-- 人気のキーワード取得関数の更新
-- subcategoryカラムからsubcategory_tags配列への変更に対応
-- このスクリプトをSupabase SQLエディタで実行してください

-- 既存の関数を削除（戻り値の型を変更するため）
DROP FUNCTION IF EXISTS get_popular_keywords(integer);

CREATE OR REPLACE FUNCTION get_popular_keywords(limit_count INT DEFAULT 5)
RETURNS TABLE (
  keyword TEXT,
  score DOUBLE PRECISION
) AS $$
DECLARE
  -- パラメータ設定 --
  _w_rating NUMERIC := 10.0;
  _w_review_count NUMERIC := 1.0;
  _decay_rate NUMERIC := 30.0;
BEGIN
  RETURN QUERY
  WITH tag_stats AS (
    -- subcategory_tags配列を展開して各タグを個別に処理
    SELECT
      unnest(p.subcategory_tags) AS tag,
      r.rating,
      r.created_at
    FROM
      products p
    JOIN
      reviews r ON p.id = r.product_id
    WHERE
      p.subcategory_tags IS NOT NULL AND array_length(p.subcategory_tags, 1) > 0
  ),
  aggregated_stats AS (
    -- タグごとに集計
    SELECT
      ts.tag,
      COUNT(*) AS review_count,
      AVG(ts.rating) AS avg_rating,
      MAX(ts.created_at) AS last_review_date
    FROM
      tag_stats ts
    GROUP BY
      ts.tag
  )
  SELECT
    ag.tag AS keyword,
    -- final_score の計算（元のアルゴリズムを維持）
    (
      (ag.avg_rating * _w_rating) + (ag.review_count * _w_review_count)
    )
    *
    (
      1.0 / (1.0 + (EXTRACT(EPOCH FROM (NOW() - ag.last_review_date)) / 86400) / _decay_rate)
    ) AS score
  FROM
    aggregated_stats ag
  ORDER BY
    score DESC
  LIMIT
    limit_count;
END;
$$ LANGUAGE plpgsql;

-- 動作確認用クエリ
-- SELECT * FROM get_popular_keywords(5);
