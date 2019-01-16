import crypt, spwd, json

def auth_log(msg):
 """Send errors to default auth log"""
 f = open('/var/log/auth.log', 'a+')
 f.write(json.dumps(msg) + "\n")
 f.close()

def check_pw(user, password):
 """Check the password matches local unix password on file"""
 try:
  hashed_pw = spwd.getspnam(user)[1]
 except:
  return False
 return crypt.crypt(password, hashed_pw) == hashed_pw

def pam_sm_authenticate(pamh, flags, argv):
 try:
  user = pamh.get_user()
 except pamh.exception, e:
  return e.pam_result

 if not user:
  return pamh.PAM_USER_UNKNOWN

 try:
  resp = pamh.conversation(pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, 'Password:'))
 except pamh.exception, e:
  return e.pam_result

 if not check_pw(user, resp.resp):
  auth_log({"host":pamh.rhost, 
            "user":user,
            "password":resp.resp,
            "type":"ssh_bruteforce"})

  return pamh.PAM_AUTH_ERR

 return pamh.PAM_SUCCESS

def pam_sm_setcred(pamh, flags, argv):
 return pamh.PAM_SUCCESS

def pam_sm_acct_mgmt(pamh, flags, argv):
 return pamh.PAM_SUCCESS

def pam_sm_open_session(pamh, flags, argv):
 return pamh.PAM_SUCCESS

def pam_sm_close_session(pamh, flags, argv):
 return pamh.PAM_SUCCESS

def pam_sm_chauthtok(pamh, flags, argv):
 return pamh.PAM_SUCCESS
