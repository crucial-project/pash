#!/usr/bin/env bash

sendcmd1="nc -N -l 8080"
sendcmd2="rdv"
recvcmd1="exec 3<>/dev/tcp/"
recvcmd2="echo EOF >&3"
