function [] = add_user(user_name, short_name)
key.user_name = user_name;
key.user_name_for_var = short_name;
insert(sln_lab.User, key);
sln_lab.activate_user(user_name);