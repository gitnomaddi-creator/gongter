-- =============================================================================
-- 공터 (Gongter) - 지자체 시드 데이터
-- 총 243개: 광역 17 + 기초 226 (세종시 단층제로 기초 없음)
-- 행정코드: 법정동코드(행정안전부) 기반
-- 이메일 도메인: 행정안전부 지자체 누리집 기반 (-- unverified 표시된 항목 확인 필요)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. 광역자치단체 (17개)
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('서울특별시',       '서울특별시',           '11', 1, NULL, 'seoul.go.kr'),
('부산광역시',       '부산광역시',           '26', 1, NULL, 'busan.go.kr'),
('대구광역시',       '대구광역시',           '27', 1, NULL, 'daegu.go.kr'),
('인천광역시',       '인천광역시',           '28', 1, NULL, 'incheon.go.kr'),
('광주광역시',       '광주광역시',           '29', 1, NULL, 'gwangju.go.kr'),
('대전광역시',       '대전광역시',           '30', 1, NULL, 'daejeon.go.kr'),
('울산광역시',       '울산광역시',           '31', 1, NULL, 'ulsan.go.kr'),
('세종특별자치시',   '세종특별자치시',       '36', 1, NULL, 'sejong.go.kr'),
('경기도',           '경기도',               '41', 1, NULL, 'gg.go.kr'),
('강원특별자치도',   '강원특별자치도',       '42', 1, NULL, 'gwd.go.kr'),
('충청북도',         '충청북도',             '43', 1, NULL, 'chungbuk.go.kr'),
('충청남도',         '충청남도',             '44', 1, NULL, 'chungnam.go.kr'),
('전북특별자치도',   '전북특별자치도',       '45', 1, NULL, 'jeonbuk.go.kr'),
('전라남도',         '전라남도',             '46', 1, NULL, 'jeonnam.go.kr'),
('경상북도',         '경상북도',             '47', 1, NULL, 'gb.go.kr'),
('경상남도',         '경상남도',             '48', 1, NULL, 'gyeongnam.go.kr'),
('제주특별자치도',   '제주특별자치도',       '49', 1, NULL, 'jeju.go.kr');

-- ---------------------------------------------------------------------------
-- 2. 기초자치단체 - 서울특별시 (25개구)
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('종로구',     '서울특별시 종로구',     '11110', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'jongno.go.kr'),
('중구',       '서울특별시 중구',       '11140', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'junggu.seoul.kr'),
('용산구',     '서울특별시 용산구',     '11170', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'yongsan.go.kr'),
('성동구',     '서울특별시 성동구',     '11200', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'sd.go.kr'),
('광진구',     '서울특별시 광진구',     '11215', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'gwangjin.go.kr'),
('동대문구',   '서울특별시 동대문구',   '11230', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'ddm.go.kr'),
('중랑구',     '서울특별시 중랑구',     '11260', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'jungnang.go.kr'),
('성북구',     '서울특별시 성북구',     '11290', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'sb.go.kr'),
('강북구',     '서울특별시 강북구',     '11305', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'gangbuk.go.kr'),
('도봉구',     '서울특별시 도봉구',     '11320', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'dobong.go.kr'),
('노원구',     '서울특별시 노원구',     '11350', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'nowon.kr'),               -- unverified (go.kr 아님)
('은평구',     '서울특별시 은평구',     '11380', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'ep.go.kr'),
('서대문구',   '서울특별시 서대문구',   '11410', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'sdm.go.kr'),
('마포구',     '서울특별시 마포구',     '11440', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'mapo.go.kr'),
('양천구',     '서울특별시 양천구',     '11470', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'yangcheon.go.kr'),
('강서구',     '서울특별시 강서구',     '11500', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'gangseo.seoul.kr'),        -- unverified
('구로구',     '서울특별시 구로구',     '11530', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'guro.go.kr'),
('금천구',     '서울특별시 금천구',     '11545', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'geumcheon.go.kr'),
('영등포구',   '서울특별시 영등포구',   '11560', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'ydp.go.kr'),
('동작구',     '서울특별시 동작구',     '11590', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'dongjak.go.kr'),
('관악구',     '서울특별시 관악구',     '11620', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'gwanak.go.kr'),
('서초구',     '서울특별시 서초구',     '11650', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'seocho.go.kr'),
('강남구',     '서울특별시 강남구',     '11680', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'gangnam.go.kr'),
('송파구',     '서울특별시 송파구',     '11710', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'songpa.go.kr'),
('강동구',     '서울특별시 강동구',     '11740', 2, (SELECT id FROM municipalities WHERE admin_code = '11'), 'gangdong.go.kr');

-- ---------------------------------------------------------------------------
-- 3. 기초자치단체 - 부산광역시 (16개 구/군)
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('중구',       '부산광역시 중구',       '26110', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'bsjunggu.go.kr'),
('서구',       '부산광역시 서구',       '26140', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'bsseogu.go.kr'),
('동구',       '부산광역시 동구',       '26170', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'bsdonggu.go.kr'),
('영도구',     '부산광역시 영도구',     '26200', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'yeongdo.go.kr'),
('부산진구',   '부산광역시 부산진구',   '26230', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'busanjin.go.kr'),
('동래구',     '부산광역시 동래구',     '26260', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'dongnae.go.kr'),
('남구',       '부산광역시 남구',       '26290', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'bsnamgu.go.kr'),
('북구',       '부산광역시 북구',       '26320', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'bsbukgu.go.kr'),
('해운대구',   '부산광역시 해운대구',   '26350', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'haeundae.go.kr'),
('사하구',     '부산광역시 사하구',     '26380', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'saha.go.kr'),
('금정구',     '부산광역시 금정구',     '26410', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'geumjeong.go.kr'),
('강서구',     '부산광역시 강서구',     '26440', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'bsgangseo.go.kr'),
('연제구',     '부산광역시 연제구',     '26470', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'yeonje.go.kr'),
('수영구',     '부산광역시 수영구',     '26500', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'suyeong.go.kr'),
('사상구',     '부산광역시 사상구',     '26530', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'sasang.go.kr'),
('기장군',     '부산광역시 기장군',     '26710', 2, (SELECT id FROM municipalities WHERE admin_code = '26'), 'gijang.go.kr');

-- ---------------------------------------------------------------------------
-- 4. 기초자치단체 - 대구광역시 (8개 구 + 1개 군 = 9개)
--    군위군: 2023.07.01 경상북도에서 대구광역시로 편입
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('중구',       '대구광역시 중구',       '27110', 2, (SELECT id FROM municipalities WHERE admin_code = '27'), 'jung.daegu.kr'),          -- unverified
('동구',       '대구광역시 동구',       '27140', 2, (SELECT id FROM municipalities WHERE admin_code = '27'), 'dong.daegu.kr'),          -- unverified
('서구',       '대구광역시 서구',       '27170', 2, (SELECT id FROM municipalities WHERE admin_code = '27'), 'dgs.go.kr'),
('남구',       '대구광역시 남구',       '27200', 2, (SELECT id FROM municipalities WHERE admin_code = '27'), 'nam.daegu.kr'),           -- unverified
('북구',       '대구광역시 북구',       '27230', 2, (SELECT id FROM municipalities WHERE admin_code = '27'), 'buk.daegu.kr'),           -- unverified
('수성구',     '대구광역시 수성구',     '27260', 2, (SELECT id FROM municipalities WHERE admin_code = '27'), 'suseong.kr'),             -- unverified (go.kr 아님)
('달서구',     '대구광역시 달서구',     '27290', 2, (SELECT id FROM municipalities WHERE admin_code = '27'), 'dalseo.daegu.kr'),        -- unverified
('달성군',     '대구광역시 달성군',     '27710', 2, (SELECT id FROM municipalities WHERE admin_code = '27'), 'dalseong.daegu.kr'),      -- unverified
('군위군',     '대구광역시 군위군',     '27720', 2, (SELECT id FROM municipalities WHERE admin_code = '27'), 'gunwi.go.kr');            -- unverified (편입 후 코드 추정)

-- ---------------------------------------------------------------------------
-- 5. 기초자치단체 - 인천광역시 (8개 구 + 2개 군 = 10개)
--    미추홀구: 2018.07.01 남구에서 개칭
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('중구',       '인천광역시 중구',       '28110', 2, (SELECT id FROM municipalities WHERE admin_code = '28'), 'icjg.go.kr'),
('동구',       '인천광역시 동구',       '28140', 2, (SELECT id FROM municipalities WHERE admin_code = '28'), 'icdonggu.go.kr'),
('미추홀구',   '인천광역시 미추홀구',   '28177', 2, (SELECT id FROM municipalities WHERE admin_code = '28'), 'michu.incheon.kr'),       -- unverified
('연수구',     '인천광역시 연수구',     '28185', 2, (SELECT id FROM municipalities WHERE admin_code = '28'), 'yeonsu.go.kr'),
('남동구',     '인천광역시 남동구',     '28200', 2, (SELECT id FROM municipalities WHERE admin_code = '28'), 'namdong.go.kr'),
('부평구',     '인천광역시 부평구',     '28237', 2, (SELECT id FROM municipalities WHERE admin_code = '28'), 'icbp.go.kr'),
('계양구',     '인천광역시 계양구',     '28245', 2, (SELECT id FROM municipalities WHERE admin_code = '28'), 'gyeyang.go.kr'),
('서구',       '인천광역시 서구',       '28260', 2, (SELECT id FROM municipalities WHERE admin_code = '28'), 'seo.incheon.kr'),         -- unverified
('강화군',     '인천광역시 강화군',     '28710', 2, (SELECT id FROM municipalities WHERE admin_code = '28'), 'ganghwa.go.kr'),
('옹진군',     '인천광역시 옹진군',     '28720', 2, (SELECT id FROM municipalities WHERE admin_code = '28'), 'ongjin.go.kr');

-- ---------------------------------------------------------------------------
-- 6. 기초자치단체 - 광주광역시 (5개구)
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('동구',       '광주광역시 동구',       '29110', 2, (SELECT id FROM municipalities WHERE admin_code = '29'), 'donggu.kr'),              -- unverified (go.kr 아님)
('서구',       '광주광역시 서구',       '29140', 2, (SELECT id FROM municipalities WHERE admin_code = '29'), 'seogu.gwangju.kr'),       -- unverified
('남구',       '광주광역시 남구',       '29155', 2, (SELECT id FROM municipalities WHERE admin_code = '29'), 'namgu.gwangju.kr'),       -- unverified
('북구',       '광주광역시 북구',       '29170', 2, (SELECT id FROM municipalities WHERE admin_code = '29'), 'bukgu.gwangju.kr'),       -- unverified
('광산구',     '광주광역시 광산구',     '29200', 2, (SELECT id FROM municipalities WHERE admin_code = '29'), 'gwangsan.go.kr');

-- ---------------------------------------------------------------------------
-- 7. 기초자치단체 - 대전광역시 (5개구)
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('동구',       '대전광역시 동구',       '30110', 2, (SELECT id FROM municipalities WHERE admin_code = '30'), 'donggu.go.kr'),           -- unverified (대전 동구)
('중구',       '대전광역시 중구',       '30140', 2, (SELECT id FROM municipalities WHERE admin_code = '30'), 'djjunggu.go.kr'),
('서구',       '대전광역시 서구',       '30170', 2, (SELECT id FROM municipalities WHERE admin_code = '30'), 'seogu.go.kr'),            -- unverified (대전 서구)
('유성구',     '대전광역시 유성구',     '30200', 2, (SELECT id FROM municipalities WHERE admin_code = '30'), 'yuseong.go.kr'),
('대덕구',     '대전광역시 대덕구',     '30230', 2, (SELECT id FROM municipalities WHERE admin_code = '30'), 'daedeok.go.kr');

-- ---------------------------------------------------------------------------
-- 8. 기초자치단체 - 울산광역시 (4개구 + 1개군 = 5개)
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('중구',       '울산광역시 중구',       '31110', 2, (SELECT id FROM municipalities WHERE admin_code = '31'), 'junggu.ulsan.kr'),        -- unverified
('남구',       '울산광역시 남구',       '31140', 2, (SELECT id FROM municipalities WHERE admin_code = '31'), 'ulsannamgu.go.kr'),
('동구',       '울산광역시 동구',       '31170', 2, (SELECT id FROM municipalities WHERE admin_code = '31'), 'donggu.ulsan.kr'),        -- unverified
('북구',       '울산광역시 북구',       '31200', 2, (SELECT id FROM municipalities WHERE admin_code = '31'), 'bukgu.ulsan.kr'),         -- unverified
('울주군',     '울산광역시 울주군',     '31710', 2, (SELECT id FROM municipalities WHERE admin_code = '31'), 'ulju.ulsan.kr');           -- unverified

-- ---------------------------------------------------------------------------
-- 9. 세종특별자치시 - 기초자치단체 없음 (단층제)
--    세종시는 광역이자 기초 역할을 동시에 수행
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 10. 기초자치단체 - 경기도 (28개 시 + 3개 군 = 31개)
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('수원시',     '경기도 수원시',         '41110', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'suwon.go.kr'),
('성남시',     '경기도 성남시',         '41130', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'seongnam.go.kr'),
('의정부시',   '경기도 의정부시',       '41150', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'ui4u.go.kr'),             -- unverified
('안양시',     '경기도 안양시',         '41170', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'anyang.go.kr'),
('부천시',     '경기도 부천시',         '41190', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'bucheon.go.kr'),
('광명시',     '경기도 광명시',         '41210', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'gm.go.kr'),
('평택시',     '경기도 평택시',         '41220', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'pyeongtaek.go.kr'),
('동두천시',   '경기도 동두천시',       '41250', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'ddc.go.kr'),
('안산시',     '경기도 안산시',         '41270', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'ansan.go.kr'),
('고양시',     '경기도 고양시',         '41280', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'goyang.go.kr'),
('과천시',     '경기도 과천시',         '41290', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'gccity.go.kr'),           -- unverified
('구리시',     '경기도 구리시',         '41310', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'guri.go.kr'),
('남양주시',   '경기도 남양주시',       '41360', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'nyj.go.kr'),
('오산시',     '경기도 오산시',         '41370', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'osan.go.kr'),
('시흥시',     '경기도 시흥시',         '41390', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'siheung.go.kr'),
('군포시',     '경기도 군포시',         '41410', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'gunpo.go.kr'),
('의왕시',     '경기도 의왕시',         '41430', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'uiwang.go.kr'),
('하남시',     '경기도 하남시',         '41450', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'hanam.go.kr'),
('용인시',     '경기도 용인시',         '41460', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'yongin.go.kr'),
('파주시',     '경기도 파주시',         '41480', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'paju.go.kr'),
('이천시',     '경기도 이천시',         '41500', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'icheon.go.kr'),
('안성시',     '경기도 안성시',         '41550', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'anseong.go.kr'),
('김포시',     '경기도 김포시',         '41570', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'gimpo.go.kr'),
('화성시',     '경기도 화성시',         '41590', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'hscity.go.kr'),           -- unverified
('광주시',     '경기도 광주시',         '41610', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'gjcity.go.kr'),           -- unverified
('양주시',     '경기도 양주시',         '41630', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'yangju.go.kr'),
('포천시',     '경기도 포천시',         '41650', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'pocheon.go.kr'),
('여주시',     '경기도 여주시',         '41670', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'yeoju.go.kr'),
('연천군',     '경기도 연천군',         '41800', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'yeoncheon.go.kr'),
('가평군',     '경기도 가평군',         '41820', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'gp.go.kr'),
('양평군',     '경기도 양평군',         '41830', 2, (SELECT id FROM municipalities WHERE admin_code = '41'), 'yp21.go.kr');             -- unverified

-- ---------------------------------------------------------------------------
-- 11. 기초자치단체 - 강원특별자치도 (7개 시 + 11개 군 = 18개)
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('춘천시',     '강원특별자치도 춘천시',     '42110', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'chuncheon.go.kr'),
('원주시',     '강원특별자치도 원주시',     '42130', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'wonju.go.kr'),
('강릉시',     '강원특별자치도 강릉시',     '42150', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'gn.go.kr'),
('동해시',     '강원특별자치도 동해시',     '42170', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'dh.go.kr'),
('태백시',     '강원특별자치도 태백시',     '42190', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'taebaek.go.kr'),
('속초시',     '강원특별자치도 속초시',     '42210', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'sokcho.go.kr'),
('삼척시',     '강원특별자치도 삼척시',     '42230', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'samcheok.go.kr'),
('홍천군',     '강원특별자치도 홍천군',     '42720', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'hongcheon.go.kr'),
('횡성군',     '강원특별자치도 횡성군',     '42730', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'hsg.go.kr'),
('영월군',     '강원특별자치도 영월군',     '42750', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'yw.go.kr'),
('평창군',     '강원특별자치도 평창군',     '42760', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'pc.go.kr'),
('정선군',     '강원특별자치도 정선군',     '42770', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'jeongseon.go.kr'),
('철원군',     '강원특별자치도 철원군',     '42780', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'cwg.go.kr'),
('화천군',     '강원특별자치도 화천군',     '42790', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'ihc.go.kr'),
('양구군',     '강원특별자치도 양구군',     '42800', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'yanggu.go.kr'),
('인제군',     '강원특별자치도 인제군',     '42810', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'inje.go.kr'),
('고성군',     '강원특별자치도 고성군',     '42820', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'gwgs.go.kr'),          -- unverified
('양양군',     '강원특별자치도 양양군',     '42830', 2, (SELECT id FROM municipalities WHERE admin_code = '42'), 'yangyang.go.kr');

-- ---------------------------------------------------------------------------
-- 12. 기초자치단체 - 충청북도 (3개 시 + 8개 군 = 11개)
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('청주시',     '충청북도 청주시',       '43110', 2, (SELECT id FROM municipalities WHERE admin_code = '43'), 'cheongju.go.kr'),
('충주시',     '충청북도 충주시',       '43130', 2, (SELECT id FROM municipalities WHERE admin_code = '43'), 'chungju.go.kr'),
('제천시',     '충청북도 제천시',       '43150', 2, (SELECT id FROM municipalities WHERE admin_code = '43'), 'jecheon.go.kr'),
('보은군',     '충청북도 보은군',       '43720', 2, (SELECT id FROM municipalities WHERE admin_code = '43'), 'boeun.go.kr'),
('옥천군',     '충청북도 옥천군',       '43730', 2, (SELECT id FROM municipalities WHERE admin_code = '43'), 'oc.go.kr'),
('영동군',     '충청북도 영동군',       '43740', 2, (SELECT id FROM municipalities WHERE admin_code = '43'), 'yd21.go.kr'),             -- unverified
('증평군',     '충청북도 증평군',       '43745', 2, (SELECT id FROM municipalities WHERE admin_code = '43'), 'jp.go.kr'),
('진천군',     '충청북도 진천군',       '43750', 2, (SELECT id FROM municipalities WHERE admin_code = '43'), 'jincheon.go.kr'),
('괴산군',     '충청북도 괴산군',       '43760', 2, (SELECT id FROM municipalities WHERE admin_code = '43'), 'goesan.go.kr'),
('음성군',     '충청북도 음성군',       '43770', 2, (SELECT id FROM municipalities WHERE admin_code = '43'), 'eumseong.go.kr'),
('단양군',     '충청북도 단양군',       '43800', 2, (SELECT id FROM municipalities WHERE admin_code = '43'), 'danyang.go.kr');

-- ---------------------------------------------------------------------------
-- 13. 기초자치단체 - 충청남도 (8개 시 + 7개 군 = 15개)
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('천안시',     '충청남도 천안시',       '44130', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'cheonan.go.kr'),
('공주시',     '충청남도 공주시',       '44150', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'gongju.go.kr'),
('보령시',     '충청남도 보령시',       '44180', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'boryeong.chungnam.kr'),   -- unverified
('아산시',     '충청남도 아산시',       '44200', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'asan.go.kr'),
('서산시',     '충청남도 서산시',       '44210', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'seosan.go.kr'),
('논산시',     '충청남도 논산시',       '44230', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'nonsan.go.kr'),
('계룡시',     '충청남도 계룡시',       '44250', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'gyeryong.go.kr'),
('당진시',     '충청남도 당진시',       '44270', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'dangjin.go.kr'),
('금산군',     '충청남도 금산군',       '44710', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'geumsan.go.kr'),
('부여군',     '충청남도 부여군',       '44760', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'buyeo.go.kr'),
('서천군',     '충청남도 서천군',       '44770', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'seocheon.go.kr'),
('청양군',     '충청남도 청양군',       '44790', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'cheongyang.go.kr'),
('홍성군',     '충청남도 홍성군',       '44800', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'hongseong.go.kr'),
('예산군',     '충청남도 예산군',       '44810', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'yesan.go.kr'),
('태안군',     '충청남도 태안군',       '44825', 2, (SELECT id FROM municipalities WHERE admin_code = '44'), 'taean.go.kr');

-- ---------------------------------------------------------------------------
-- 14. 기초자치단체 - 전북특별자치도 (6개 시 + 8개 군 = 14개)
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('전주시',     '전북특별자치도 전주시',     '45110', 2, (SELECT id FROM municipalities WHERE admin_code = '45'), 'jeonju.go.kr'),
('군산시',     '전북특별자치도 군산시',     '45130', 2, (SELECT id FROM municipalities WHERE admin_code = '45'), 'gunsan.go.kr'),
('익산시',     '전북특별자치도 익산시',     '45140', 2, (SELECT id FROM municipalities WHERE admin_code = '45'), 'iksan.go.kr'),
('정읍시',     '전북특별자치도 정읍시',     '45180', 2, (SELECT id FROM municipalities WHERE admin_code = '45'), 'jeongeup.go.kr'),
('남원시',     '전북특별자치도 남원시',     '45190', 2, (SELECT id FROM municipalities WHERE admin_code = '45'), 'namwon.go.kr'),
('김제시',     '전북특별자치도 김제시',     '45210', 2, (SELECT id FROM municipalities WHERE admin_code = '45'), 'gimje.go.kr'),
('완주군',     '전북특별자치도 완주군',     '45710', 2, (SELECT id FROM municipalities WHERE admin_code = '45'), 'wanju.go.kr'),
('진안군',     '전북특별자치도 진안군',     '45720', 2, (SELECT id FROM municipalities WHERE admin_code = '45'), 'jinan.go.kr'),
('무주군',     '전북특별자치도 무주군',     '45730', 2, (SELECT id FROM municipalities WHERE admin_code = '45'), 'muju.go.kr'),
('장수군',     '전북특별자치도 장수군',     '45740', 2, (SELECT id FROM municipalities WHERE admin_code = '45'), 'jangsu.go.kr'),
('임실군',     '전북특별자치도 임실군',     '45750', 2, (SELECT id FROM municipalities WHERE admin_code = '45'), 'imsil.go.kr'),
('순창군',     '전북특별자치도 순창군',     '45770', 2, (SELECT id FROM municipalities WHERE admin_code = '45'), 'sunchang.go.kr'),
('고창군',     '전북특별자치도 고창군',     '45790', 2, (SELECT id FROM municipalities WHERE admin_code = '45'), 'gochang.go.kr'),
('부안군',     '전북특별자치도 부안군',     '45800', 2, (SELECT id FROM municipalities WHERE admin_code = '45'), 'buan.go.kr');

-- ---------------------------------------------------------------------------
-- 15. 기초자치단체 - 전라남도 (5개 시 + 17개 군 = 22개)
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('목포시',     '전라남도 목포시',       '46110', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'mokpo.go.kr'),
('여수시',     '전라남도 여수시',       '46130', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'yeosu.go.kr'),
('순천시',     '전라남도 순천시',       '46150', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'suncheon.go.kr'),
('나주시',     '전라남도 나주시',       '46170', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'naju.go.kr'),
('광양시',     '전라남도 광양시',       '46230', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'gwangyang.go.kr'),
('담양군',     '전라남도 담양군',       '46710', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'damyang.go.kr'),
('곡성군',     '전라남도 곡성군',       '46720', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'gokseong.go.kr'),
('구례군',     '전라남도 구례군',       '46730', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'gurye.go.kr'),
('고흥군',     '전라남도 고흥군',       '46770', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'goheung.go.kr'),
('보성군',     '전라남도 보성군',       '46780', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'boseong.go.kr'),
('화순군',     '전라남도 화순군',       '46790', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'hwasun.go.kr'),
('장흥군',     '전라남도 장흥군',       '46800', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'jangheung.go.kr'),
('강진군',     '전라남도 강진군',       '46810', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'gangjin.go.kr'),
('해남군',     '전라남도 해남군',       '46820', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'haenam.go.kr'),
('영암군',     '전라남도 영암군',       '46830', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'yeongam.go.kr'),
('무안군',     '전라남도 무안군',       '46840', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'muan.go.kr'),
('함평군',     '전라남도 함평군',       '46860', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'hampyeong.go.kr'),
('영광군',     '전라남도 영광군',       '46870', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'yeonggwang.go.kr'),
('장성군',     '전라남도 장성군',       '46880', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'jangseong.go.kr'),
('완도군',     '전라남도 완도군',       '46890', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'wando.go.kr'),
('진도군',     '전라남도 진도군',       '46900', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'jindo.go.kr'),
('신안군',     '전라남도 신안군',       '46910', 2, (SELECT id FROM municipalities WHERE admin_code = '46'), 'shinan.go.kr');

-- ---------------------------------------------------------------------------
-- 16. 기초자치단체 - 경상북도 (10개 시 + 12개 군 = 22개)
--     군위군은 2023.07.01 대구로 편입되어 제외
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('포항시',     '경상북도 포항시',       '47110', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'pohang.go.kr'),
('경주시',     '경상북도 경주시',       '47130', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'gyeongju.go.kr'),
('김천시',     '경상북도 김천시',       '47150', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'gc.go.kr'),
('안동시',     '경상북도 안동시',       '47170', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'andong.go.kr'),
('구미시',     '경상북도 구미시',       '47190', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'gumi.go.kr'),
('영주시',     '경상북도 영주시',       '47210', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'yeongju.go.kr'),
('영천시',     '경상북도 영천시',       '47230', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'yc.go.kr'),
('상주시',     '경상북도 상주시',       '47250', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'sangju.go.kr'),
('문경시',     '경상북도 문경시',       '47280', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'gbmg.go.kr'),             -- unverified
('경산시',     '경상북도 경산시',       '47290', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'gbgs.go.kr'),              -- unverified
('의성군',     '경상북도 의성군',       '47730', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'usc.go.kr'),
('청송군',     '경상북도 청송군',       '47750', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'cs.go.kr'),
('영양군',     '경상북도 영양군',       '47760', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'yyg.go.kr'),
('영덕군',     '경상북도 영덕군',       '47770', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'yd.go.kr'),
('청도군',     '경상북도 청도군',       '47820', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'cheongdo.go.kr'),
('고령군',     '경상북도 고령군',       '47830', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'goryeong.go.kr'),
('성주군',     '경상북도 성주군',       '47840', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'sj.go.kr'),
('칠곡군',     '경상북도 칠곡군',       '47850', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'chilgok.go.kr'),
('예천군',     '경상북도 예천군',       '47900', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'ycg.kr'),                 -- unverified (go.kr 아님)
('봉화군',     '경상북도 봉화군',       '47920', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'bonghwa.go.kr'),
('울진군',     '경상북도 울진군',       '47930', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'uljin.go.kr'),
('울릉군',     '경상북도 울릉군',       '47940', 2, (SELECT id FROM municipalities WHERE admin_code = '47'), 'ulleung.go.kr');

-- ---------------------------------------------------------------------------
-- 17. 기초자치단체 - 경상남도 (8개 시 + 10개 군 = 18개)
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('창원시',     '경상남도 창원시',       '48120', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'changwon.go.kr'),
('진주시',     '경상남도 진주시',       '48170', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'jinju.go.kr'),
('통영시',     '경상남도 통영시',       '48220', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'tongyeong.go.kr'),
('사천시',     '경상남도 사천시',       '48240', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'sacheon.go.kr'),
('김해시',     '경상남도 김해시',       '48250', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'gimhae.go.kr'),
('밀양시',     '경상남도 밀양시',       '48270', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'miryang.go.kr'),
('거제시',     '경상남도 거제시',       '48310', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'geoje.go.kr'),
('양산시',     '경상남도 양산시',       '48330', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'yangsan.go.kr'),
('의령군',     '경상남도 의령군',       '48720', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'uiryeong.go.kr'),
('함안군',     '경상남도 함안군',       '48730', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'haman.go.kr'),
('창녕군',     '경상남도 창녕군',       '48740', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'cng.go.kr'),
('고성군',     '경상남도 고성군',       '48820', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'goseong.go.kr'),
('남해군',     '경상남도 남해군',       '48840', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'namhae.go.kr'),
('하동군',     '경상남도 하동군',       '48850', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'hadong.go.kr'),
('산청군',     '경상남도 산청군',       '48860', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'sancheong.go.kr'),
('함양군',     '경상남도 함양군',       '48870', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'hygn.go.kr'),             -- unverified
('거창군',     '경상남도 거창군',       '48880', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'geochang.go.kr'),
('합천군',     '경상남도 합천군',       '48890', 2, (SELECT id FROM municipalities WHERE admin_code = '48'), 'hc.go.kr');

-- ---------------------------------------------------------------------------
-- 18. 기초자치단체 - 제주특별자치도 (2개 시)
-- ---------------------------------------------------------------------------
INSERT INTO municipalities (name, full_name, admin_code, level, parent_id, email_domain) VALUES
('제주시',     '제주특별자치도 제주시',     '49110', 2, (SELECT id FROM municipalities WHERE admin_code = '49'), 'jejusi.go.kr'),
('서귀포시',   '제주특별자치도 서귀포시',   '49130', 2, (SELECT id FROM municipalities WHERE admin_code = '49'), 'seogwipo.go.kr');

-- =============================================================================
-- 검증 쿼리 (배포 후 실행)
-- =============================================================================
-- SELECT COUNT(*) FROM municipalities WHERE level = 1;  -- 17
-- SELECT COUNT(*) FROM municipalities WHERE level = 2;  -- 226
-- SELECT COUNT(*) FROM municipalities;                   -- 243
