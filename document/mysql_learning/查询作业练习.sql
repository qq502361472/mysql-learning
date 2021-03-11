-- 求所有人物对应掌门的名称
select d.id,d.deptName,e.`name` from t_dept d left join t_emp e on e.id = d.CEO;

#1
SELECT
	te.*, tmp.`name` `掌门人`
FROM
	t_emp te
LEFT JOIN (
	SELECT
		d.id,
		d.deptName,
		e.`name`
	FROM
		t_dept d
	LEFT JOIN t_emp e ON e.id = d.CEO
) tmp ON te.deptId = tmp.id;

#2 
SELECT
	tmp.*, te.`name` `掌门人`
FROM
	(
		SELECT
			e.*, d.CEO
		FROM
			t_emp e
		LEFT JOIN t_dept d ON e.deptId = d.id
	) tmp
LEFT JOIN t_emp te ON tmp.CEO = te.id;

#3
SELECT
	e.*, (
		SELECT
			te.`NAME`
		FROM
			t_emp te
		WHERE
			te.id = d.CEO
	) `掌门人`
FROM
	t_emp e
LEFT JOIN t_dept d ON e.deptId = d.id;

#4
SELECT
	em.*, emp.`name` '掌门人'
FROM
	t_emp em
LEFT JOIN t_dept d ON em.deptId = d.id
LEFT JOIN t_emp emp ON d.CEO = emp.id;