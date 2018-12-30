#!/usr/bin/python3

import csv
import sqlite3

db = sqlite3.connect('2019.db')
c = db.cursor()
nofteams = 6
teams=[]
goals=[]
for i in range(0,nofteams):
    teams.append([])
    goals.append(0)
f = open('users.csv')
reader = csv.reader(f)
for i, row in enumerate(reader):
   goesto = goals.index(min(goals))
   teams[goesto].append([row[0], row[1], row[2]])
   goals[goesto] += float(row[2])

print("===========")
for i, t in enumerate(teams):
    print ("Команда {} (цель: {:.2f}):".format(i+1, goals[i]/52))
    print ("==========")
    for r in t:
        print(r[0], r[1], r[2])
        c.execute('INSERT OR REPLACE INTO runners  VALUES (?, ?, ?, ?)', (r[0], r[1], i+1, r[2]))
    print("")
#    c.execute('INSERT OR REPLACE INTO teams VALUES (?, ?)', (i+1,i+1))
db.commit()
db.close()
f.close()
