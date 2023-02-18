# chat_search by x0rnn
# loops through ET server log files for input player GUID (32 or 8 chars) and outputs all chat by that player to guid.txt
# in case of an encoder error, change line 23 to:
# for line in open(r'' + filename + '', encoding="ISO-8859-1"):

import glob
import re
import sys

if sys.version_info[0] < 3:
	raise Exception("Python 3.x is required!")

logs = glob.glob('etserver*.log') # change to your log name/s
found_flag = False

guid = input("GUID: ")
guid = guid.upper()

for filename in logs:
	f = open(guid + ".txt", "a+")
	f.write("### " + filename + " ###\n")
	f.close()
	for line in open(r'' + filename + ''):
		match_id = re.search(r'Userinfo:.*cl_guid\\([0-9a-fA-F]{32}).*name\\(.+?)\\', line)
		if match_id:
			if match_id.group(1) == guid or match_id.group(1)[-8:] == guid:
				name = match_id.group(2)
				if len(name) >= 36:
					name = name[:35]
				found_flag = True

		if found_flag == True:
			match_say = re.search(r'say\w*:\s*(.*):\s*(.*)', line)
			match_pm = re.search(r'etpro privmsg:\s*(.*) to (.*):\s*(.*)', line)
			if match_say or match_pm:
				f = open(guid + ".txt", "a+")
				if match_say:
					found_name = match_say.group(1)
					sentence = match_say.group(2)
					if found_name == name:
						f.write(sentence + "\n")
						f.close()
				elif match_pm:
					found_name = match_pm.group(1)
					rec = match_pm.group(2)
					sentence = match_pm.group(3)
					if found_name == name:
						f.write("PM to " + rec + ": " + sentence + "\n")
						f.close()
