#!/bin/bash
#only valid for gateway to gateway VPNs with PSK authentication and tunnel mode and ikev1

#Color the questions and output
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
white=`tput setaf 7`
reset=`tput sgr0`

function check_and_print()
{
 local r
 local file_to_print="$1"
 local add_param="$2"
 param=" "
 until [ ! -z $r ] && ([ $r = "y" ] || [ $r = "n" ]); do
 echo "${green}do you want to see possibile value?[y/n]${reset}"
 read r
 done
    if [ $r = "y" ]
    then
     cat $file_to_print
     echo "${red}Note that you might use also different value not present above${reset}"
    fi
    if [ $add_param = "n" ]
     then
       until [ ! -z $param ] ; do
         echo "${green}insert value manually${reset}"
         read param
       done
    else
      echo "${green}insert value manually${reset}"
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

#=======
echo "${green}choose a connection name: ${yellow}[empty value not allowed]${reset}"
conn_name=$(check_if_empty)
echo " "
until [ ! -z $reply ] && ([ $reply = "y" ] || [ $reply = "n" ]); do
echo "${green}do you want to enabled DPD (dead peer detection)? [y/n]${reset}"
echo "${red}TIP:DPD is used to identify the availability of the other peer${reset}"
read reply
done
case $reply in
y)
   echo "${green}set the DPD (dead peer detection) timeout ${yellow}[if empty default to 120 second]${reset}"
   echo "${red}TIP:defines the timeout interval, after which all connections to a peer are deleted in case of inactivity.${reset}"
   read dpd_timeout
   if [ -z $dpd_timeout ]
    then
      dpd_timeout="120s"
      else
       dpd_timeout="$dpd_timeout"
   fi
   echo "${green}set the DPD (dead peer detection) delay ${yellow}[if empty default to 30 seconds]${reset}"
   echo "${red}TIP:defines the period time interval with which DPD packets are sent to the peer.${reset}"
   read dpd_deleay
   if [ -z $dpd_delay ]
    then
     dpd_delay="30s"
      else
       dpd_delay="$dpd_delay"
   fi
   echo "${green}set the DPD (dead peer detection) action [restart|clear|hold] - ${yellow}[if empty default to restart]${reset}"
   read dpd_action
   if [ -z $dpd_action ]
    then
      dpd_action="restart"
   fi
   ;;
n)
   echo "${green}no DPD will be set${reset}"
   dpd_action="none"
   ;;
esac

echo "${green}set the local subnet that needs to reach the remote network ${yellow}[empty value not allowed]${reset}"
left_subnet=$(check_if_empty)

echo "${green}set the remote subnet that needs to reach the local network ${yellow}[empty value not allowed]${reset}"
rightsubnet=$(check_if_empty)

echo "${green}set the IP address of the remote public-network interface${yellow}[empty value not allowed]${reset}"
right_ip=$(check_if_empty)

echo "${green}set the IP address of the local public-network interface${yellow}[empty value not allowed]${reset}"
left_ip=$(check_if_empty)
echo " "
until [ ! -z $ike_lifetime ] && [[ "$ike_lifetime" =~ ^-?[0-9]+$ ]]; do
echo "${green}set the lifetime of the ike keying channel (in hours)${yellow}[empty value not allowed]${reset}"
read ike_lifetime
done
ike_lifetime=$ike_lifetime"h"
echo " "
until [ ! -z $lifetime ] && [[ "$lifetime" =~ ^-?[0-9]+$ ]]; do
echo "${green}set the lifetime of the connection from successful negotiation to expiry${yellow}[empty value not allowed]${reset}"
read lifetime
done
lifetime=$lifetime"h"

echo "${green}set the ike encryption/authentication [phase 1] algorithms to be used${reset}"
echo "${green}ike encryption${yellow}[empty value not allowed]${reset}"
check_and_print enc.txt n
ike_enc=$param

echo "${green}ike integrity${yellow}[empty value not allowed]${reset}"
check_and_print int.txt n
ike_int=$param

echo "${green}ike dhgroup${reset}"
check_and_print dh.txt n
ike_dh=$param

echo "${green}set the esp encryption/authentication [phase 2] algorithms to be used for the connection${reset}"

echo "${green}esp encryption${reset}"
check_and_print enc.txt n
esp_enc=$param

echo "${green}esp integrity${reset}"
check_and_print int.txt n
esp_int=$param

echo "${green}esp dhgroup [empty to not use it]${reset}"
check_and_print dh.txt y
esp_dh=$param

echo "${green}set how the tunnel needs to be treated during the strongswan start [possibile values are start|route|add] - ${yellow}[if empty default to start]${reset}"
echo "${red}start: loads a connection and brings it up immediately [initiator behviour]${reset}"
echo "${red}route: If traffic is detected between local and remote, a connection is established${reset}"
echo "${red}add: loads a connection without starting it.it won't start the connection immediatly: but waits that the other peer starts it [responder behaviour]${reset}"
read auto

echo "${green}set the ID of the local peer [i.e fqdn or ip] - ${yellow}[if empty default to IP address of the local public-network interface]${reset}"
read local_id
if [ -z $local_id ]
then
  local_id="$left_ip"
fi
echo " "

echo "${green}set the ID of the remote peer [i.e fqdn or ip] - ${yellow}[if empty default to IP address of the remote public-network interface]${reset}"
read remote_id
if [ -z $remote_id ]
then
  remote_id="$right_ip"
fi

echo "${green}do you want to enable compression IPComp ${yellow}[possibile value yes|no - if empty set to disabled]${reset}"
read comp

echo "${yellow}add in your ipsec.secret file these values${reset}"
echo "${white} $local_id  $remote_id : PSK "\"Yoursupersecretpassword\""${reset}"
echo " "
echo "${yellow}copy and paste the below lines in your ipsec.conf file${reset}"
echo "${white}======================================================${reset}"
echo "${white}conn $conn_name${reset}"
echo "${white}    type=tunnel${reset}"
echo "${white}    keyexchange=ikev1${reset}"
echo "${white}    leftauth=psk${reset}"
echo "${white}    rightauth=psk${reset}"
if [ $reply = "y" ]
then
echo "${white}    dpdtimeout=$dpd_timeout${reset}"
echo "${white}    dpddelay=$dpd_delay${reset}"
fi
echo "${white}    dpdaction=$dpd_action${reset}"
echo "${white}    leftsubnet=$left_subnet${reset}"
echo "${white}    rightsubnet=$rightsubnet${reset}"
echo "${white}    right=$right_ip${reset}"
echo "${white}    left=$left_ip${reset}"
echo "${white}    ikelifetime=$ike_lifetime${reset}"
echo "${white}    lifetime=$lifetime${reset}"
echo "${white}    ike=$ike_enc"-"$ike_int"-"$ike_dh!${reset}"
if [ ! -z $esp_dh ]
 then
   echo "${white}    esp=$esp_enc-$esp_int-$esp_dh!${reset}"
else
   echo "${white}    esp=$esp_enc-$esp_int!${reset}"
fi
if [ ! -z $auto ]
 then
   echo "${white}    auto=$auto${reset}"
 else
   echo "${white}    auto=start${reset}"
fi
echo "${white}    leftid=$local_id${reset}"
echo "${white}    rightid=$remote_id${reset}"
if [ ! -z $comp ] && [ $comp = "yes" ]
 then
   echo "${white}    compress=$comp${reset}"
fi
echo "${white}=====================================================${reset}"
