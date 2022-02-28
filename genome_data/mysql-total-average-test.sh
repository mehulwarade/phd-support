#!/bin/sh

select 

mysql -u root -pz phd -ss -e "select timestamp,description,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,(p1+p2+p3+p4+p5+p6+p8+p9+p10+p11+p12+p13+p14) AS TOTAL FROM teest";


# Get total of every row inot a column
# Get the average of the column


select sum(p1+p2+p3+p4+p5+p6+p9+p10+p11+p12+p13+p14) AS TOTAL FROM teest;

select avg(p1+p2+p3) AS TOTAL FROM 3n_300mb_i75 where timestamp between 1644625451 and 1644637835;