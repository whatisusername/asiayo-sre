SELECT DISTINCT c.class
FROM (
    SELECT
        name,
        DENSE_RANK() OVER (ORDER BY score DESC) AS ranking
    FROM score
) AS ranked
JOIN class AS c
    ON ranked.name = c.name
WHERE ranked.ranking = 2;
