function [] = deactivate_user(user_name)
delQuick(sln_lab.ActiveUser & sprintf('user_name="%s"',user_name));