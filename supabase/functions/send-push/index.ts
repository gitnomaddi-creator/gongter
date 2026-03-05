import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const serviceAccountJson = JSON.parse(
  Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!,
);

const FCM_PROJECT_ID = "gongter-app";

// --- JWT / OAuth2 for FCM HTTP v1 API ---

function base64url(data: Uint8Array): string {
  return btoa(String.fromCharCode(...data))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(
    new TextEncoder().encode(JSON.stringify({ alg: "RS256", typ: "JWT" })),
  );
  const payload = base64url(
    new TextEncoder().encode(
      JSON.stringify({
        iss: serviceAccountJson.client_email,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: "https://oauth2.googleapis.com/token",
        iat: now,
        exp: now + 3600,
      }),
    ),
  );

  // Import RSA private key
  const pemContents = serviceAccountJson.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");
  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  // Sign JWT
  const sigInput = new TextEncoder().encode(`${header}.${payload}`);
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, sigInput),
  );
  const jwt = `${header}.${payload}.${base64url(signature)}`;

  // Exchange JWT for OAuth2 access token
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const tokenData = await tokenRes.json();

  if (!tokenData.access_token) {
    console.error("Failed to get access token:", tokenData);
    throw new Error("Failed to get FCM access token");
  }

  return tokenData.access_token;
}

// --- FCM send ---

async function sendFcm(
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<{ success: boolean; unregistered: boolean }> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          data,
          android: { priority: "high" },
          apns: {
            payload: { aps: { sound: "default", badge: 1 } },
          },
        },
      }),
    },
  );

  const result = await res.json();

  if (!res.ok) {
    const errorCode = result?.error?.details?.[0]?.errorCode ?? "";
    console.error("FCM error:", JSON.stringify(result));
    return { success: false, unregistered: errorCode === "UNREGISTERED" };
  }

  console.log("FCM sent:", result.name);
  return { success: true, unregistered: false };
}

// --- Main handler ---

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record;

    if (!record) {
      return new Response(JSON.stringify({ error: "No record" }), {
        status: 400,
      });
    }

    // Skip system notifications (announcements use FCM topic, not individual push)
    if (record.type === "system") {
      return new Response(JSON.stringify({ skipped: "system" }), {
        status: 200,
      });
    }

    const userId = record.user_id;
    if (!userId) {
      return new Response(JSON.stringify({ error: "No user_id" }), {
        status: 400,
      });
    }

    // Get user's FCM token
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("fcm_token")
      .eq("id", userId)
      .single();

    if (profileError || !profile?.fcm_token) {
      console.log("No FCM token for user:", userId);
      return new Response(JSON.stringify({ skipped: "no_token" }), {
        status: 200,
      });
    }

    // Send FCM push
    const accessToken = await getAccessToken();
    const { success, unregistered } = await sendFcm(
      accessToken,
      profile.fcm_token,
      record.title ?? "공터",
      record.body ?? "",
      {
        target_type: record.target_type ?? "",
        target_id: record.target_id ?? "",
      },
    );

    // Clean up invalid token
    if (unregistered) {
      await supabase
        .from("profiles")
        .update({ fcm_token: null })
        .eq("id", userId);
      console.log("Cleared invalid FCM token for user:", userId);
    }

    return new Response(JSON.stringify({ success }), { status: 200 });
  } catch (err) {
    console.error("send-push error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
    });
  }
});
