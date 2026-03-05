import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const serviceAccountJson = JSON.parse(
  Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!,
);

const FCM_PROJECT_ID = "gongter-app";

// --- JWT / OAuth2 (same as send-push) ---

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

  const sigInput = new TextEncoder().encode(`${header}.${payload}`);
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, sigInput),
  );
  const jwt = `${header}.${payload}.${base64url(signature)}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const tokenData = await tokenRes.json();

  if (!tokenData.access_token) {
    throw new Error("Failed to get FCM access token");
  }
  return tokenData.access_token;
}

// --- Main handler ---

Deno.serve(async (req) => {
  try {
    // Verify caller is authenticated
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "No auth" }), {
        status: 401,
      });
    }

    const { title, body } = await req.json();
    if (!title) {
      return new Response(JSON.stringify({ error: "Title required" }), {
        status: 400,
      });
    }

    // Use the caller's JWT to verify admin role
    const token = authHeader.replace("Bearer ", "");
    const callerClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });

    // Get caller's profile
    const {
      data: { user },
    } = await callerClient.auth.getUser(token);
    if (!user) {
      return new Response(JSON.stringify({ error: "Invalid user" }), {
        status: 401,
      });
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey);
    const { data: profile } = await adminClient
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (profile?.role !== "admin") {
      return new Response(JSON.stringify({ error: "Admin only" }), {
        status: 403,
      });
    }

    // 1. Send FCM topic message
    const accessToken = await getAccessToken();
    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            topic: "announcements",
            notification: { title, body: body ?? "" },
            data: { target_type: "announcement", target_id: "" },
            android: { priority: "high" },
            apns: {
              payload: { aps: { sound: "default", badge: 1 } },
            },
          },
        }),
      },
    );
    const fcmResult = await fcmRes.json();
    console.log("FCM topic sent:", JSON.stringify(fcmResult));

    // 2. Insert notifications for all active users (except admin)
    const { error: insertError } = await adminClient.rpc(
      "insert_announcement_notifications",
      { p_title: title, p_body: body ?? "" },
    );

    if (insertError) {
      console.error("Insert error:", insertError);
      return new Response(
        JSON.stringify({ error: insertError.message }),
        { status: 500 },
      );
    }

    return new Response(
      JSON.stringify({ success: true, fcm: fcmResult }),
      { status: 200 },
    );
  } catch (err) {
    console.error("send-announcement error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
    });
  }
});
