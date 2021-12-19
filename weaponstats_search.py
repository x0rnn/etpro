# weaponstats_search by x0rnn
# loops through ET server log files for input player GUID (32 or 8 chars) and outputs acc/hs acc stats for that player to 'weaponstats.txt'
# in case of an encoder error, change line 41 to:
# for line in open(r'' + filename + '', encoding="ISO-8859-1"):

import glob
import re
from collections import defaultdict
import sys

if sys.version_info[0] < 3:
	raise Exception("Python 3.x is required!")

logs = glob.glob('etserver*.log') # change to your log name/s
players = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
m = [0, 1, 2, 4, 8, 16, 32 , 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576, 2097152]
weaponstats = defaultdict(dict)
prev_line = None
found_flag = False

def a2b(number): #thanks to adawolfa
	bits = []

	i = 1
	while 2 ** (i + 1) < number:
		i += 1

	while i >= 0:
		if 2 ** i <= number:
			bits.append(2 ** i)
			number = number - 2 ** i
		i -= 1

	return(bits, len(bits))

guid = input("GUID: ")
guid = guid.upper()

for filename in logs:
	line_n = 0
	for line in open(r'' + filename + ''):
		line_n += 1
		mapname = re.search(r'InitGame:.*mapname\\(.+?)\\', line)
		if mapname:
			nameofmap = mapname.group(1)
		if prev_line:
			comb_lines = prev_line + line
			match_id = re.search(r'ClientConnect:\s*(\d{1,2})\n.*Userinfo:.*cl_guid\\([0-9a-fA-F]{32}).*name\\(.+?)\\', comb_lines)
			if match_id:
				name = match_id.group(3)
				name = re.sub(r'\^\^', '©', name)
				name = re.sub(r'\^.', '', name)
				name = re.sub(r'©', '^', name)
				if match_id.group(2) == guid or match_id.group(2)[-8:] == guid:
					players[int(match_id.group(1))] = [match_id.group(2), name]
					found_flag = True
					found_id = match_id.group(1)

			if found_flag == True:
				match_ws = re.search(r'WeaponStats:\s*(\d{1,2})\s*\d\s*(\d*)\s*(.*)', line)
				if match_ws:
					id = int(match_ws.group(1))
					if found_id == str(id):
						if players[id] != 0:
							mask = int(match_ws.group(2))
							if mask not in m:
								bits, bits_len = a2b(int(match_ws.group(2)))
								j = 0
								knife = False
								w = 0
								for j in range(bits_len):
									if bits[j] == 1 or bits[j] == 2 or bits[j] == 4 or bits[j] == 8 or bits[j] == 16 or bits[j] == 32:
										if bits[j] == 1:
											knife = True
										else:
											w += 1
								if w != 0:
									if knife == True:
										if w == 1:
											match_wm = re.search(r'\d*\s*\d*\s*\d*\s*\d*\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*.*', match_ws.group(3))
											hits = int(match_wm.group(1))
											shots = int(match_wm.group(2))
											kills = int(match_wm.group(3))
											hs = int(match_wm.group(4))
											weaponstats[id] = [hits, shots, kills, hs]
										elif w == 2:
											match_wm = re.search(r'\d*\s*\d*\s*\d*\s*\d*\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*.*', match_ws.group(3))
											hits1 = int(match_wm.group(1))
											shots1 = int(match_wm.group(2))
											kills1 = int(match_wm.group(3))
											hs1 = int(match_wm.group(4))
											hits2 = int(match_wm.group(5))
											shots2 = int(match_wm.group(6))
											kills2 = int(match_wm.group(7))
											hs2 = int(match_wm.group(8))
											weaponstats[id] = [hits1+hits2, shots1+shots2, kills1+kills2, hs1+hs2]
										elif w == 3:
											match_wm = re.search(r'\d*\s*\d*\s*\d*\s*\d*\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*.*', match_ws.group(3))
											hits1 = int(match_wm.group(1))
											shots1 = int(match_wm.group(2))
											kills1 = int(match_wm.group(3))
											hs1 = int(match_wm.group(4))
											hits2 = int(match_wm.group(5))
											shots2 = int(match_wm.group(6))
											kills2 = int(match_wm.group(7))
											hs2 = int(match_wm.group(8))
											hits3 = int(match_wm.group(9))
											shots3 = int(match_wm.group(10))
											kills3 = int(match_wm.group(11))
											hs3 = int(match_wm.group(12))
											weaponstats[id] = [hits1+hits2+hits3, shots1+shots2+shots3, kills1+kills2+kills3, hs1+hs2+hs3]
										elif w == 4:
											match_wm = re.search(r'\d*\s*\d*\s*\d*\s*\d*\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*.*', match_ws.group(3))
											hits1 = int(match_wm.group(1))
											shots1 = int(match_wm.group(2))
											kills1 = int(match_wm.group(3))
											hs1 = int(match_wm.group(4))
											hits2 = int(match_wm.group(5))
											shots2 = int(match_wm.group(6))
											kills2 = int(match_wm.group(7))
											hs2 = int(match_wm.group(8))
											hits3 = int(match_wm.group(9))
											shots3 = int(match_wm.group(10))
											kills3 = int(match_wm.group(11))
											hs3 = int(match_wm.group(12))
											hits4 = int(match_wm.group(13))
											shots4 = int(match_wm.group(14))
											kills4 = int(match_wm.group(15))
											hs4 = int(match_wm.group(16))
											weaponstats[id] = [hits1+hits2+hits3+hits4, shots1+shots2+shots3+shots4, kills1+kills2+kills3+kills4, hs1+hs2+hs3+hs4]
										elif w == 5:
											match_wm = re.search(r'\d*\s*\d*\s*\d*\s*\d*\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*.*', match_ws.group(3))
											hits1 = int(match_wm.group(1))
											shots1 = int(match_wm.group(2))
											kills1 = int(match_wm.group(3))
											hs1 = int(match_wm.group(4))
											hits2 = int(match_wm.group(5))
											shots2 = int(match_wm.group(6))
											kills2 = int(match_wm.group(7))
											hs2 = int(match_wm.group(8))
											hits3 = int(match_wm.group(9))
											shots3 = int(match_wm.group(10))
											kills3 = int(match_wm.group(11))
											hs3 = int(match_wm.group(12))
											hits4 = int(match_wm.group(13))
											shots4 = int(match_wm.group(14))
											kills4 = int(match_wm.group(15))
											hs4 = int(match_wm.group(16))
											hits5 = int(match_wm.group(17))
											shots5 = int(match_wm.group(18))
											kills5 = int(match_wm.group(19))
											hs5 = int(match_wm.group(20))
											weaponstats[id] = [hits1+hits2+hits3+hits4+hits5, shots1+shots2+shots3+shots4+shots5, kills1+kills2+kills3+kills4+kills5, hs1+hs2+hs3+hs4+hs5]
									else:
										if w == 1:
											match_wm = re.search(r'\d*\s*\d*\s*\d*\s*\d*\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*.*', match_ws.group(3))
											hits = int(match_wm.group(1))
											shots = int(match_wm.group(2))
											kills = int(match_wm.group(3))
											hs = int(match_wm.group(4))
											weaponstats[id] = [hits, shots, kills, hs]
										elif w == 2:
											match_wm = re.search(r'\d*\s*\d*\s*\d*\s*\d*\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*.*', match_ws.group(3))
											hits1 = int(match_wm.group(1))
											shots1 = int(match_wm.group(2))
											kills1 = int(match_wm.group(3))
											hs1 = int(match_wm.group(4))
											hits2 = int(match_wm.group(5))
											shots2 = int(match_wm.group(6))
											kills2 = int(match_wm.group(7))
											hs2 = int(match_wm.group(8))
											weaponstats[id] = [hits1+hits2, shots1+shots2, kills1+kills2, hs1+hs2]
										elif w == 3:
											match_wm = re.search(r'\d*\s*\d*\s*\d*\s*\d*\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*.*', match_ws.group(3))
											hits1 = int(match_wm.group(1))
											shots1 = int(match_wm.group(2))
											kills1 = int(match_wm.group(3))
											hs1 = int(match_wm.group(4))
											hits2 = int(match_wm.group(5))
											shots2 = int(match_wm.group(6))
											kills2 = int(match_wm.group(7))
											hs2 = int(match_wm.group(8))
											hits3 = int(match_wm.group(9))
											shots3 = int(match_wm.group(10))
											kills3 = int(match_wm.group(11))
											hs3 = int(match_wm.group(12))
											weaponstats[id] = [hits1+hits2+hits3, shots1+shots2+shots3, kills1+kills2+kills3, hs1+hs2+hs3]
										elif w == 4:
											match_wm = re.search(r'\d*\s*\d*\s*\d*\s*\d*\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*.*', match_ws.group(3))
											hits1 = int(match_wm.group(1))
											shots1 = int(match_wm.group(2))
											kills1 = int(match_wm.group(3))
											hs1 = int(match_wm.group(4))
											hits2 = int(match_wm.group(5))
											shots2 = int(match_wm.group(6))
											kills2 = int(match_wm.group(7))
											hs2 = int(match_wm.group(8))
											hits3 = int(match_wm.group(9))
											shots3 = int(match_wm.group(10))
											kills3 = int(match_wm.group(11))
											hs3 = int(match_wm.group(12))
											hits4 = int(match_wm.group(13))
											shots4 = int(match_wm.group(14))
											kills4 = int(match_wm.group(15))
											hs4 = int(match_wm.group(16))
											weaponstats[id] = [hits1+hits2+hits3+hits4, shots1+shots2+shots3+shots4, kills1+kills2+kills3+kills4, hs1+hs2+hs3+hs4]
										elif w == 5:
											match_wm = re.search(r'\d*\s*\d*\s*\d*\s*\d*\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*.*', match_ws.group(3))
											hits1 = int(match_wm.group(1))
											shots1 = int(match_wm.group(2))
											kills1 = int(match_wm.group(3))
											hs1 = int(match_wm.group(4))
											hits2 = int(match_wm.group(5))
											shots2 = int(match_wm.group(6))
											kills2 = int(match_wm.group(7))
											hs2 = int(match_wm.group(8))
											hits3 = int(match_wm.group(9))
											shots3 = int(match_wm.group(10))
											kills3 = int(match_wm.group(11))
											hs3 = int(match_wm.group(12))
											hits4 = int(match_wm.group(13))
											shots4 = int(match_wm.group(14))
											kills4 = int(match_wm.group(15))
											hs4 = int(match_wm.group(16))
											hits5 = int(match_wm.group(17))
											shots5 = int(match_wm.group(18))
											kills5 = int(match_wm.group(19))
											hs5 = int(match_wm.group(20))
											weaponstats[id] = [hits1+hits2+hits3+hits4+hits5, shots1+shots2+shots3+shots4+shots5, kills1+kills2+kills3+kills4+kills5, hs1+hs2+hs3+hs4+hs5]
								else:
									weaponstats[id] = [0, 0, 0, 0]
							else:
								if mask == 2 or mask == 4 or mask == 8 or mask == 16 or mask == 32:
									match_wm = re.search(r'(\d*)\s*(\d*)\s*(\d*)\s*\d*\s*(\d*)\s*.*', match_ws.group(3))
									hits = int(match_wm.group(1))
									shots = int(match_wm.group(2))
									kills = int(match_wm.group(3))
									hs = int(match_wm.group(4))
									weaponstats[id] = [hits, shots, kills, hs]
								else:
									weaponstats[id] = [0, 0, 0, 0]

							if int(weaponstats[id][0]) > 1 and int(weaponstats[id][3]) > 1:
								acc = round((int(weaponstats[id][0]) / int(weaponstats[id][1])) * 100, 2)
								hs_acc = round((int(weaponstats[id][3]) / int(weaponstats[id][0])) * 100, 2)
								f = open("weaponstats.txt", "a+")
								f.write("Name: " + players[id][1] + "\nGUID: " + players[id][0] + "\nMapname: " + str(nameofmap) + "\n")
								f.write("Filename: " + filename + " Line: " + str(line_n) + "\n")
								f.write("Kills: " + str(weaponstats[id][2]) + " Acc: " + str(acc) + "% HS acc: " + str(hs_acc) + "% HS: " + str(weaponstats[id][3]) + "\n\n")
								f.close()
							found_flag = False
			prev_line = line
		else:
			prev_line = line
