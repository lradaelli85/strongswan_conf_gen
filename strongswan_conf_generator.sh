#!/bin/bash
#only valid for gateway to gateway VPNs with PSK authentication and tunnel mode and ikev1

function check_and_print()
{
  local r
  local file_to_print="$1"
  local add_param="$2"
  param=" "
  until [ ! -z $r ] && ([ $r = "y" ] || [ $r = "n" ]); do
    echo "do you want to see possibile value?[y/n]"
    read r
  done
  if [ $r = "y" ]
  then
    cat $file_to_print
    echo "Note that you might use also different value not present above"
  fi
  if [ $add_param = "n" ]
  then
    until [ ! -z $param ] ; do
      echo "insert value manually"
      read param
    done
  else
    echo "insert value manually"
    read param
  fi
}
function check_if_empty()
{
  local p
  until [ ! -z $p ]; do
    read p
  done
  echo "$p"
}

clear

echo "choose a connection name: [empty value not allowed]"
conn_name=$(check_if_empty)
echo " "
until [ ! -z $reply ] && ([ $reply = "y" ] || [ $reply = "n" ]); do
  echo "do you want to enabled DPD (dead peer detection)? [y/n]"
  echo "TIP:DPD is used to identify the availability of the other peer"
  read reply
done
case $reply in
  y)
  echo "set the DPD (dead peer detection) timeout [if empty default to 120 second]"
  echo "TIP:defines the timeout interval, after which all connections to a peer are deleted in case of inactivity."
  read dpd_timeout
  if [ -z $dpd_timeout ]
  then
    dpd_timeout="120s"
  else
    dpd_timeout="$dpd_timeout"s
  fi
  echo " "
  echo "set the DPD (dead peer detection) delay [if empty default to 30 seconds]"
  echo "TIP:defines the period time interval with which DPD packets are sent to the peer."
  read dpd_deleay
  if [ -z $dpd_delay ]
  then
    dpd_delay="30s"
  else
    dpd_delay="$dpd_deleay"s
  fi
  echo " "
  echo "set the DPD (dead peer detection) action [restart|clear|hold - if empty default to restart]"
  read dpd_action
  if [ -z $dpd_action]
  then
    dpd_action="restart"
  fi
  ;;
  n)
  echo "no DPD will be set"
  dpd_action="none"
  ;;
esac
echo " "
echo "set the local subnet that needs to reach the remote network [empty value not allowed]"
echo " "
left_subnet=$(check_if_empty)
echo " "
echo "set the remote subnet that needs to reach the local network [empty value not allowed]"
echo " "
rightsubnet=$(check_if_empty)
echo " "
echo "set the IP/fqdn address of the remote public-network interface"
right_ip=$(check_if_empty)
echo " "
echo "set the IP/fqdn address of the local public-network interface"
left_ip=$(check_if_empty)
echo " "
until [ ! -z $ike_lifetime ] && [[ "$ike_lifetime" =~ ^-?[0-9]+$ ]]; do
  echo "set the lifetime of the ike keying channel (in hours)"
  read ike_lifetime
done
ike_lifetime=$ike_lifetime"h"
echo " "
until [ ! -z $lifetime ] && [[ "$lifetime" =~ ^-?[0-9]+$ ]]; do
  echo "set the lifetime of the connection from successful negotiation to expiry"
  read lifetime
done
lifetime=$lifetime"h"
echo " "
echo "set the ike encryption/authentication [phase 1] algorithms to be used"
echo "ike encryption"
check_and_print enc.txt n
ike_enc=$param
echo " "
echo "ike integrity"
check_and_print int.txt n
ike_int=$param
echo " "
echo "ike dhgroup"
check_and_print dh.txt n
ike_dh=$param
echo " "
echo "set the esp encryption/authentication [phase 2] algorithms to be used for the connection"
echo " "
echo "esp encryption"
check_and_print enc.txt n
esp_enc=$param
echo " "
echo "esp integrity"
check_and_print int.txt n
esp_int=$param
echo " "
echo "esp dhgroup [empty to not use it]"
check_and_print dh.txt y
esp_dh=$param
echo " "
echo "set how the tunnel needs to be treated during the strongswan start [possibile values are start|route|add - if empty default to start]"
echo " "
echo "start: loads a connection and brings it up immediately [initiator behviour]"
echo "route: If traffic is detected between local and remote, a connection is established"
echo "add: loads a connection without starting it.it won't start the connection immediatly: but waits that the other peer starts it [responder behaviour]"
read auto
echo " "
echo "set the ID of the local peer [i.e fqdn or ip - if empty default to IP address of the local public-network interface]"
read local_id
if [ -z $local_id ]
then
  local_id="$left_ip"
fi
echo " "
echo "set the ID of the remote peer [i.e fqdn or ip - if empty default to IP address of the remote public-network interface]"
read remote_id
if [ -z $remote_id ]
then
  remote_id="$right_ip"
fi
echo " "
echo "do you want to enable compression IPComp [possibile value yes|no - if empty set to disabled]"
read comp
echo " "
echo "add in your ipsec.secret file the blow value"
echo ""$local_id  $remote_id : PSK "\"Yoursupersecretpassword\""
echo " "
echo "copy and paste the below lines in your ipsec.conf file"
echo "======================================================"
echo "conn $conn_name"
echo "type=tunnel"
echo "keyexchange=ikev1"
echo "leftauth=psk"
echo "rightauth=psk"
if [ $reply = "y" ]
then
  echo "dpdtimeout=$dpd_timeout"
  echo "dpddelay=$dpd_delay"
fi
echo "dpdaction=$dpd_action"
echo "leftsubnet=$left_subnet"
echo "rightsubnet=$rightsubnet"
echo "right=$right_ip"
echo "left=$left_ip"
echo "ikelifetime=$ike_lifetime"
echo "lifetime=$lifetime"
echo "ike=$ike_enc"-"$ike_int"-"$ike_dh!"
if [ ! -z $esp_dh ]
then
  echo "esp=$esp_enc-$esp_int-$esp_dh!"
else
  echo "esp=$esp_enc-$esp_int!"
fi
if [ ! -z $auto ]
then
  echo "auto=$auto"
else
  echo "auto=start"
fi
echo "leftid=$local_id"
echo "rightid=$remote_id"
if [ ! -z $comp ] && [ $comp = "yes" ]
then
  echo "compress=$comp"
fi
echo "====================================================="
