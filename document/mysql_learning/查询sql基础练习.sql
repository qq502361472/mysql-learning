-- 列出自己的掌门比自己年龄小的人员
SELECT
	em.*
FROM
	t_emp em
LEFT JOIN t_dept d ON em.deptId = d.id
LEFT JOIN t_emp emp ON d.CEO = emp.id
where emp.age<em.age;

-- 列出所有年龄低于自己门派平均年龄的人员
select * from t_emp e left join t_dept d on e.deptId = d.id;
select d.id,avg(e.age) from t_emp e left join t_dept d on e.deptId = d.id group by d.id;
SELECT
	*
FROM
	t_emp te
LEFT JOIN (
	SELECT
		d.id,
		avg(e.age) avgAge
	FROM
		t_emp e
	LEFT JOIN t_dept d ON e.deptId = d.id
	GROUP BY
		d.id
) tmp ON te.deptId = tmp.id
WHERE
	te.age < tmp.avgAge;
-- 列出至少有2个年龄大于40的成员的门派
SELECT
	*
FROM
	t_dept td
LEFT JOIN (
	SELECT
		d.id,
		count(1) count
	FROM
	 t_dept d
LEFT JOIN t_emp e ON e.deptId = d.id and e.age > 40
	GROUP BY
		d.id
) tmp ON td.id = tmp.id
WHERE
	tmp.count >= 2;
-- 至少有2位非掌门人成员的门派
SELECT
	*
FROM
	t_dept td
LEFT JOIN (
	SELECT
		d.id,
		count(1) count
	FROM
		t_dept d
	LEFT JOIN t_emp e ON e.deptId = d.id
	AND d.CEO != e.id
	GROUP BY
		d.id
) tmp ON td.id = tmp.id
WHERE
	tmp.count >= 2;
-- 列出全部人员，并增加一列备注“是否为掌门人”
select * from t_emp e left join t_dept d on e.deptId = d.id;
SELECT
	e.*, (
		CASE
		WHEN d.CEO = e.id THEN
			'是'
		ELSE
			'否'
		END
	) `是否掌门人`
FROM
	t_emp e
LEFT JOIN t_dept d ON e.deptId = d.id;
-- 列出全部门派，并增加一列备注“老鸟or菜鸟”，门派平均年龄>50显示“老鸟”，否则“菜鸟”
SELECT
	td.*, CASE
WHEN tmp.avgAge > 50 THEN
	'老鸟'
ELSE
	'菜鸟'
END '老鸟or菜鸟'
FROM
	t_dept td
LEFT JOIN (
	SELECT
		d.id,
		avg(e.age) avgAge
	FROM
		t_dept d
	LEFT JOIN t_emp e ON d.id = e.deptId
	GROUP BY
		d.id
) tmp ON td.id = tmp.id;
-- 显示每个门派年龄最大的人
select * from t_emp e left join t_dept d on e.deptId = d.id;
SELECT
	*
FROM
	(
		SELECT
			d.*, max(e.age) maxAge
		FROM
			t_dept d
		LEFT JOIN t_emp e ON d.id = e.deptId
		GROUP BY
			d.id
	) tmp
LEFT JOIN t_emp e ON e.deptId = tmp.id
AND e.age = maxAge;


-- 显示每个门派年龄第二大的人
SELECT
	*
FROM
	(
		SELECT
			tmp.*, max(te.age) secAge
		FROM
			(
				SELECT
					d.*, max(e.age) maxAge
				FROM
					t_dept d
				LEFT JOIN t_emp e ON d.id = e.deptId
				GROUP BY
					d.id
			) tmp
		LEFT JOIN t_emp te ON te.deptId = tmp.id
		AND te.age != tmp.maxAge
		GROUP BY
			tmp.id
	) tmp2
LEFT JOIN t_emp temp ON temp.deptId = tmp2.id
AND temp.age = tmp2.secAge;


show index from t_emp;

