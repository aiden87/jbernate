CREATE OR REPLACE VIEW MN_MKJAVA_META_VI
AS
/* 
  하이버네이트 자바 객체 만들기 위해 테이블/컬럼 정보 추출
  
  PK는 SEQ 하나만 존재
   B->A<-C 의 1:1관계는 안됨( A가 메인이고, 1:1로 B와 C가 있으면 안됨 )
   
-- DB명 AS DB_NM
-- 테이블명 AS TAB_NM
-- 테이블설명 AS TAB_DESC
-- 컬럼명 AS COL_NM
-- 컬럼설명 AS COL_DESC
-- 컬럼타입 AS COL_TYPE
-- 컬럼크기 AS COL_LEN
-- 컬럼PRECISION AS COL_PREC
-- 컬럼SCALE AS COL_SCALE
-- 컬럼NULLABLE AS COL_NULL ( Y/N )
-- 컬럼순서 AS COL_SEQ
-- PK여부 AS IS_PK ( Y/N )
-- 관계타입 AS R_CNT( 2 = 1:1, 1 = 1:N, 0 = 관계없음 )
-- 관계테이블,컬럼명 AS REF_TAB_N_COL( TT_TEST_B,SEQ 즉 테이블,컬럼 형태 )
*/
SELECT 
    COL.OWNER AS DB_NM
  , COL.TABLE_NAME AS TAB_NM
  , TCM.COMMENTS AS TAB_DESC
  , COL.COLUMN_NAME AS COL_NM 
  , CCM.COMMENTS AS COL_DESC
  , COL.DATA_TYPE AS COL_TYPE
  , COL.DATA_LENGTH AS COL_LEN
  , COL.DATA_PRECISION AS COL_PREC
  , COL.DATA_SCALE AS COL_SCALE
  , COL.NULLABLE AS COL_NULL
  , COL.COLUMN_ID AS COL_SEQ
  , NVL( PKT.IS_PK , 'N' ) AS IS_PK
  , NVL( REL.CNT, '0' ) AS R_CNT
  , RTN.REF_TAB_N_COL AS REF_TAB_N_COL
FROM ALL_TAB_COLUMNS COL
INNER JOIN ALL_TAB_COMMENTS TCM   -- 테이블 코멘트
  ON  COL.OWNER       = TCM.OWNER
  AND COL.TABLE_NAME  = TCM.TABLE_NAME
  AND TCM.TABLE_TYPE  = 'TABLE'
INNER JOIN ALL_COL_COMMENTS CCM   -- 컬럼 코멘트
  ON  COL.OWNER       = CCM.OWNER
  AND COL.TABLE_NAME  = CCM.TABLE_NAME
  AND COL.COLUMN_NAME = CCM.COLUMN_NAME
LEFT OUTER JOIN (
  SELECT 
    'Y' AS IS_PK
    , C.COLUMN_NAME
    , C.TABLE_NAME
  FROM ALL_CONS_COLUMNS C, All_CONSTRAINTS A
  WHERE C.CONSTRAINT_NAME = A.CONSTRAINT_NAME
    AND C.TABLE_NAME      = A.TABLE_NAME        
    AND A.CONSTRAINT_TYPE = 'P'            
) PKT --// PK여부
  ON  PKT.TABLE_NAME      = COL.TABLE_NAME
  AND PKT.COLUMN_NAME     = COL.COLUMN_NAME
LEFT OUTER JOIN(
  SELECT COUNT( C.COLUMN_NAME ) AS CNT
    , MAX( C.CONSTRAINT_NAME ) AS CONSTRAINT_NAME
    , C.TABLE_NAME
    , C.COLUMN_NAME
  FROM ALL_CONS_COLUMNS C, All_CONSTRAINTS A
  WHERE C.CONSTRAINT_NAME = A.CONSTRAINT_NAME
    AND C.TABLE_NAME      = A.TABLE_NAME        
    AND ( A.CONSTRAINT_TYPE = 'P' OR A.CONSTRAINT_TYPE = 'R' )
  GROUP BY C.COLUMN_NAME, C.TABLE_NAME, C.COLUMN_NAME
) REL --// 관계 타입
  ON  REL.TABLE_NAME      = COL.TABLE_NAME
  AND REL.COLUMN_NAME     = COL.COLUMN_NAME
LEFT OUTER JOIN(
  SELECT ( D.TABLE_NAME || ',' || D.COLUMN_NAME ) REF_TAB_N_COL
        , C.TABLE_NAME
        , C.COLUMN_NAME
  FROM ALL_CONS_COLUMNS C, All_CONSTRAINTS A, ALL_CONS_COLUMNS D
  WHERE C.CONSTRAINT_NAME = A.CONSTRAINT_NAME        
    AND A.CONSTRAINT_TYPE = 'R'
    AND A.R_CONSTRAINT_NAME = D.CONSTRAINT_NAME
) RTN --// 관계 테이블,컬럼
  ON  RTN.TABLE_NAME      = COL.TABLE_NAME
  AND RTN.COLUMN_NAME     = COL.COLUMN_NAME
--WHERE COL.OWNER IN( 'CM', 'TT' )
ORDER BY COL.OWNER ASC, COL.TABLE_NAME ASC, COL.COLUMN_ID ASC
;