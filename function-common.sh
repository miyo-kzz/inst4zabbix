function enable_rhel()
{
  local ret=0
  local name="$1"

  if [ -x /usr/bin/systemctl ]; then
    systemctl enable ${name}.service
  else
    chkconfig --add $name
    chkconfig $name on
  fi
  ret=$?

  return $ret
}

function enable_debian()
{
  :;
}
