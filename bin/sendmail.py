#!/bin/env python
# -*- coding: utf-8 -*-
"""
#/************************************************************************
# * Copyright (c) 2011 doujinshuai (doujinshuai@gmail.com)
# * Last Modified: 07-03-2013
# * 
# * Description: send mail by smtp
# * 
# * Example: python sendmail.py -f a@a.com -t b@b.com -s 'monitor' -c '127.0.0.1 is down'
# ************************************************************************/
"""

import smtplib, mimetypes
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.image import MIMEImage

class SendMail():
	def __init__ (self, mail_host="", mail_port="", mail_user="", mail_pass="", mail_helo=""):
		self.mail_host = mail_host 
		self.mail_port = mail_port
		self.mail_user = mail_user
		self.mail_pass = mail_pass
		self.mail_helo = mail_helo and mail_host[mail_host.index('.')+1:]

	def __get__(self, obj):
		return self.boj

	def __set__(self, obj, val):
		self.obj = val

	def send(self, mail_from, mail_to , mail_subject, content):
		msg = MIMEMultipart()
		msg['From'] = mail_from
		msg['To'] = mail_to
		msg['Subject'] = mail_subject
		mail_content = MIMEText(content)
		msg.attach(mail_content)

		try:
			smtp = smtplib.SMTP( self.mail_host, self.mail_port )
			#smtp.helo()
			#smtp.starttls()
			smtp.login(self.mail_user, self.mail_pass)
			smtp.sendmail(mail_from, mail_to, msg.as_string())
			smtp.quit()
			return True
		except smtplib.SMTPException:
			return False

def usage():
	print("Usage:%s [option]" % sys.argv[0])
	print("\t-h\n\t-f\n\t-t\n\t-s\n\t-c\n\t-u\n\t-p\n\t-H\n\t-P")
	print ("\t--help\n\t--from\n\t--to\n\t--subject\n\t--content\n\t--user\n\t--password\n\t--host\n\t--port")

if __name__ == "__main__":
	import sys
	import getopt
	if len(sys.argv) < 2:
		usage()
		sys.exit(1)
			

	try:
		opts, args = getopt.getopt(sys.argv[1:], "hf:t:s:c:u:p:H:P:", ["help","from=","to=","subject=","content=","user=","password=","host=","port="])
		for opt, arg in opts:
			if opt in ("-f", "--from"):
				mail_from = arg
			elif opt in ("-t", "--to"):
				mail_to = arg
			elif opt in ("-s", "--subject"):
				subject = arg
			elif opt in ("-c", "--content"):
				content = arg
			elif opt in ("-u", "--user"):
				user = arg
			elif opt in ("-p", "--password"):
				password = arg
			elif opt in ("-H", "--host"):
				host = arg
			elif opt in ("-P", "--port"):
				port = arg
			elif opt in ("-h", "--help"):
				usage()
				sys.exit(1)
			else:
				usage()
				sys.exit(1)
	
		#mt = SendMail(host, port, user, password)
		mt = SendMail('smtp.163.com', 25, 'monitor_klsd@163.com', 'monitor@zabbix')
		if mt.send(mail_from, mail_to, subject, content):
			print 'send success'
		else:
			print 'send failed'

	except getopt.GetoptError:
		usage()
		sys.exit(1)
