"""공터 더미 데이터 - SQL 직접 실행"""
import json
import urllib.request
import uuid
import random
from datetime import datetime, timedelta

PROJECT_REF = "lvqgmcrwdkmcgqkwkdlq"
ACCESS_TOKEN = "sbp_501e19c69823efe532c6fbe6aa27a49c56f58c70"
SEOUL_ID = "a1747338-b9ed-4e7e-aa1b-6606766b0486"
MASTER_ID = "eee90e1e-d099-485b-a2fc-981b3bbb1b5d"

def run_sql(query):
    url = f"https://api.supabase.com/v1/projects/{PROJECT_REF}/database/query"
    data = json.dumps({"query": query}).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Authorization", f"Bearer {ACCESS_TOKEN}")
    req.add_header("Content-Type", "application/json")
    req.add_header("User-Agent", "supabase-cli/1.0")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode())

# 1. 더미 유저 생성 (auth.users + profiles)
print("=== 더미 유저 생성 ===")
dummy_ids = []
for i in range(1, 9):
    uid = str(uuid.uuid4())
    dummy_ids.append(uid)
    email = f"dummy{i}@gongter.test"
    nickname = f"익명공무원{i}"

    sql = f"""
    INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('{uid}', '00000000-0000-0000-0000-000000000000', '{email}',
            crypt('testpass123!', gen_salt('bf')),
            now(), now(), now(), 'authenticated', 'authenticated')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO profiles (id, nickname, municipality_id, is_verified, created_at, updated_at)
    VALUES ('{uid}', '{nickname}', '{SEOUL_ID}', true, now(), now())
    ON CONFLICT (id) DO NOTHING;
    """
    try:
        run_sql(sql)
        print(f"  User {i}: {uid[:8]}... ({nickname})")
    except Exception as e:
        print(f"  User {i}: ERROR - {e}")

ALL_AUTHORS = [MASTER_ID] + dummy_ids

# 2. 게시글 데이터
POSTS = [
    {"tag": "free", "title": "오늘 점심 뭐 드셨나요?",
     "content": "구내식당 메뉴가 또 카레입니다... 이번 주만 벌써 두 번째인데 다른 분들은 점심 어떻게 해결하시나요? 밖에 나가자니 시간도 없고 도시락 싸오자니 귀찮고ㅠ",
     "view_count": 156, "like_count": 23, "comment_count": 4},
    {"tag": "free", "title": "퇴근 후 자기계발 뭐 하시나요",
     "content": "요즘 퇴근하면 너무 피곤해서 아무것도 못하겠어요. 그래도 뭔가 하고 싶은데 다른 분들은 퇴근 후에 어떤 자기계발 하시는지 궁금합니다.",
     "view_count": 234, "like_count": 41, "comment_count": 5},
    {"tag": "free", "title": "벚꽃 시즌 연차 쓸 사람 +1",
     "content": "다음 주부터 벚꽃 핀다는데 연차 쓰고 꽃구경 가고 싶네요. 올해는 꼭 여의도 가보려구요.",
     "view_count": 89, "like_count": 35, "comment_count": 3},
    {"tag": "free", "title": "공무원 하길 잘했다 싶은 순간",
     "content": "오늘 친구들 만났는데 다들 회사 야근에 시달리고 있더라구요. 물론 우리도 바쁘지만 그래도 안정적인 건 확실한 것 같아요. 여러분은 언제 잘했다 싶으셨나요?",
     "view_count": 412, "like_count": 67, "comment_count": 5},
    {"tag": "question", "title": "승진 시험 준비 어떻게 하셨나요?",
     "content": "올해 7급 승진 시험 준비하려고 하는데 선배님들 조언 부탁드립니다. 기출문제 위주로 하면 되나요? 아니면 별도 학원을 다녀야 할까요?",
     "view_count": 287, "like_count": 18, "comment_count": 3},
    {"tag": "question", "title": "타 부서 전보 신청 경험 있으신 분?",
     "content": "현재 부서에서 3년째인데 다른 부서로 옮기고 싶습니다. 전보 신청 절차가 어떻게 되나요?",
     "view_count": 178, "like_count": 12, "comment_count": 3},
    {"tag": "question", "title": "재택근무 가능한 부서가 있나요?",
     "content": "코로나 때는 재택도 했었는데 요즘은 전면 출근이잖아요. 혹시 아직도 재택근무가 가능한 부서나 업무가 있을까요?",
     "view_count": 203, "like_count": 28, "comment_count": 2},
    {"tag": "info", "title": "2026년 공무원 봉급표 정리",
     "content": "올해 봉급 인상률 3.3%% 확정됐습니다. 호봉별로 정리해봤어요.\n\n5급 1호봉: 2,014,800원\n6급 1호봉: 1,802,400원\n7급 1호봉: 1,648,100원\n8급 1호봉: 1,537,500원\n9급 1호봉: 1,432,600원",
     "view_count": 1523, "like_count": 89, "comment_count": 4},
    {"tag": "info", "title": "맞춤형 복지포인트 사용 꿀팁",
     "content": "복지포인트 연말에 소멸되니까 미리 쓰세요! 건강검진, 자기계발, 여행 등에 사용 가능합니다. 영수증 꼭 챙기세요~",
     "view_count": 678, "like_count": 56, "comment_count": 3},
    {"tag": "info", "title": "공무원 대출 금리 비교 (2026년 2월)",
     "content": "공무원 신용대출 금리 비교해봤습니다.\n\n- 하나은행: 연 3.2%%\n- 국민은행: 연 3.4%%\n- 신한은행: 연 3.3%%\n- 공무원연금공단: 연 2.8%%\n\n공무원연금공단이 가장 저렴하네요.",
     "view_count": 892, "like_count": 72, "comment_count": 3},
    {"tag": "humor", "title": "오늘의 민원 레전드.jpg",
     "content": "민원인: 제가 낸 세금이 얼만데 이런 서비스를 받아야 합니까!\n나: (속으로) 저도 세금 내는데요...\n\n매일 새로운 레전드가 탄생하는 민원실입니다 ㅋㅋ",
     "view_count": 567, "like_count": 98, "comment_count": 5},
    {"tag": "humor", "title": "결재라인이 7단계인 건에 대하여",
     "content": "담당 → 주무관 → 팀장 → 과장 → 국장 → 부시장 → 시장\n\n간단한 공문 하나 보내는데 결재가 일주일 걸립니다 ㅋㅋㅋ",
     "view_count": 445, "like_count": 87, "comment_count": 3},
    {"tag": "humor", "title": "공무원 3대 거짓말",
     "content": "1. 이거 금방 끝나요\n2. 올해는 야근 없을 거예요\n3. 내년에는 인원 충원해줄게요\n\n세 번째가 제일 아픕니다...",
     "view_count": 723, "like_count": 112, "comment_count": 6},
    {"tag": "free", "title": "새로 부임한 과장님이 좋은 분이셨으면",
     "content": "다음 달에 과장님이 바뀌신다고 하는데 제발 좋은 분이 오셨으면 좋겠어요. 워라밸 중시하는 분이면 최고겠다",
     "view_count": 198, "like_count": 33, "comment_count": 2},
    {"tag": "question", "title": "공무원 해외여행 신고 안 하면 어떻게 되나요?",
     "content": "이번 여름에 일본 여행 계획 중인데 해외여행 신고 절차가 번거롭네요. 혹시 안 하고 갔다가 걸리면 징계 대상인가요?",
     "view_count": 341, "like_count": 15, "comment_count": 3},
    {"tag": "info", "title": "연가보상비 계산 방법 정리",
     "content": "연가보상비는 미사용 연가일수 x (본봉 / 30)으로 계산합니다.\n\n7급 5호봉 기준 미사용 5일이면 약 350,000원입니다.",
     "view_count": 456, "like_count": 44, "comment_count": 2},
]

COMMENTS = {
    "오늘 점심 뭐 드셨나요?": [
        "저도 카레 질렸어요ㅠ 편의점 도시락이 나은 듯",
        "근처에 괜찮은 백반집 있어서 거기 가요",
        "구내식당 개선 건의 넣어보세요!",
        "저는 그냥 컵라면이요... 시간이 없어서",
    ],
    "퇴근 후 자기계발 뭐 하시나요": [
        "저는 퇴근 후 헬스장 다니고 있어요. 스트레스 해소에 최고!",
        "행정사 자격증 준비 중입니다",
        "유튜브로 영어 공부 중인데 꾸준히 하기가 힘드네요",
        "솔직히 넷플릭스가 자기계발입니다 ㅋㅋ",
        "저는 코딩 배우고 있어요. 파이썬 재밌더라구요",
    ],
    "공무원 하길 잘했다 싶은 순간": [
        "연금 생각하면 버틸 수 있습니다",
        "명절 보너스 나올 때요 ㅋㅋ",
        "친구들 구조조정 당할 때... 미안하지만 안정감 느꼈어요",
        "육아휴직 자유롭게 쓸 수 있을 때!",
        "퇴근시간 딱 맞춰서 나갈 때 (부서바이 부서)",
    ],
    "승진 시험 준비 어떻게 하셨나요?": [
        "기출 3회독이면 충분합니다",
        "스터디 그룹 만들어서 같이 준비하는 거 추천드려요",
        "인강 들으면서 출퇴근 시간 활용했어요",
    ],
    "2026년 공무원 봉급표 정리": [
        "정리 감사합니다! 북마크 해둘게요",
        "3.3%%... 물가 상승률 생각하면 실질적으로는 줄어든 거 아닌가요",
        "그래도 올랐으니 감사합니다 ㅠㅠ",
        "성과급은 언제 나오나요?",
    ],
    "오늘의 민원 레전드.jpg": [
        "ㅋㅋㅋㅋ 공감 100%%",
        "민원실 근무하시는 분들 진짜 존경합니다",
        "저도 비슷한 경험 있어요... 세금 얘기는 클래식이죠",
        "민원실 3년차인데 이제 웃으면서 대응합니다 ㅋ",
        "멘탈 관리가 제일 중요한 부서...",
    ],
    "결재라인이 7단계인 건에 대하여": [
        "우리는 5단계인데도 힘든데 7단계라니",
        "전자결재 시스템 도입하고 좀 나아지지 않았나요?",
        "과장님 출장 = 업무 올스톱 공감합니다",
    ],
    "공무원 3대 거짓말": [
        "4번 추가요: 이번 인사이동 때 고려해줄게",
        "ㅋㅋㅋ 3번은 진짜 매년 듣는 거 맞음",
        "저희 부서는 올해는 예산 넉넉해도 추가ㅋㅋ",
        "너무 공감돼서 눈물이 나요 ㅋㅋㅋ",
        "인원 충원... 영원한 떡밥",
        "5번: 다음에는 맛있는 거 사줄게 (회식비 없음)",
    ],
    "맞춤형 복지포인트 사용 꿀팁": [
        "꿀팁 감사합니다! 저도 안경 맞춰야겠어요",
        "여행 경비로 쓸 수 있는 건 몰랐어요",
        "연말에 한꺼번에 쓰려면 정산이 귀찮더라구요",
    ],
    "공무원 해외여행 신고 안 하면 어떻게 되나요?": [
        "신고 안 하면 징계 사유 됩니다. 꼭 하세요!",
        "절차 번거로워도 그냥 하는 게 마음 편해요",
        "복무담당에게 물어보면 서식 알려줄 거예요",
    ],
}

# 3. 게시글 삽입
print("\n=== 게시글 삽입 ===")
now = datetime.utcnow()
post_ids = {}

for i, p in enumerate(POSTS):
    pid = str(uuid.uuid4())
    hours_ago = random.randint(1, 72)
    created = (now - timedelta(hours=hours_ago, minutes=random.randint(0, 59))).strftime("%Y-%m-%d %H:%M:%S")
    author = random.choice(ALL_AUTHORS)

    title_escaped = p["title"].replace("'", "''")
    content_escaped = p["content"].replace("'", "''")

    sql = f"""
    INSERT INTO posts (id, author_id, municipality_id, tag, title, content, view_count, like_count, comment_count, created_at, updated_at)
    VALUES ('{pid}', '{author}', '{SEOUL_ID}', '{p["tag"]}', '{title_escaped}', '{content_escaped}',
            {p["view_count"]}, {p["like_count"]}, {p["comment_count"]},
            '{created}', '{created}')
    ON CONFLICT (id) DO NOTHING;
    """
    try:
        run_sql(sql)
        post_ids[p["title"]] = pid
        tag_label = {"free": "자유", "question": "질문", "info": "정보", "humor": "유머"}
        print(f"  [{tag_label[p['tag']]}] {p['title'][:30]}...")
    except Exception as e:
        print(f"  ERROR: {p['title'][:20]}... - {e}")

# 4. 댓글 삽입
print("\n=== 댓글 삽입 ===")
comment_total = 0
for title, comments in COMMENTS.items():
    pid = post_ids.get(title)
    if not pid:
        continue
    for content in comments:
        cid = str(uuid.uuid4())
        hours_ago = random.randint(0, 48)
        created = (now - timedelta(hours=hours_ago, minutes=random.randint(0, 59))).strftime("%Y-%m-%d %H:%M:%S")
        author = random.choice(ALL_AUTHORS)
        content_escaped = content.replace("'", "''")

        sql = f"""
        INSERT INTO comments (id, post_id, author_id, content, created_at, updated_at)
        VALUES ('{cid}', '{pid}', '{author}', '{content_escaped}', '{created}', '{created}')
        ON CONFLICT (id) DO NOTHING;
        """
        try:
            run_sql(sql)
            comment_total += 1
        except Exception as e:
            print(f"  Comment ERROR: {e}")

print(f"  총 {comment_total}개 댓글")

# 5. 좋아요 + 북마크 (마스터 계정)
print("\n=== 좋아요 & 북마크 ===")
like_count = 0
bookmark_count = 0
for title, pid in post_ids.items():
    if random.random() > 0.4:
        sql = f"INSERT INTO likes (post_id, user_id) VALUES ('{pid}', '{MASTER_ID}') ON CONFLICT DO NOTHING;"
        try:
            run_sql(sql)
            like_count += 1
        except:
            pass
    if random.random() > 0.7:
        sql = f"INSERT INTO bookmarks (post_id, user_id) VALUES ('{pid}', '{MASTER_ID}') ON CONFLICT DO NOTHING;"
        try:
            run_sql(sql)
            bookmark_count += 1
        except:
            pass

print(f"  좋아요 {like_count}개, 북마크 {bookmark_count}개")

print(f"\n=== 완료! ===")
print(f"유저 {len(dummy_ids)}명, 게시글 {len(post_ids)}개, 댓글 {comment_total}개")
