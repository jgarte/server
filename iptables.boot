#!/bin/sh

for IPT in iptables ip6tables; do
	[ -f /etc/iptables.ports ] && while read -r port; do
		$IPT -A INPUT -p tcp --dport "$port" -j ACCEPT
		$IPT -A INPUT -p udp --dport "$port" -j ACCEPT
	done < /etc/iptables.ports
	$IPT -A INPUT -p tcp --dport 80 -j ACCEPT
	$IPT -A INPUT -p tcp --dport 443 -j ACCEPT
	$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	$IPT -A INPUT -i lo -j ACCEPT
	$IPT -A INPUT -j DROP
	$IPT -A OUTPUT -j ACCEPT
	$IPT -A OUTPUT -o lo -j ACCEPT
done
