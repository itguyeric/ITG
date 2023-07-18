#!/bin/sh

if ! [ $* ]
then
  echo "Usage: fakenamegen.sh <number>"
  echo "<number> is the number of fake names you want to generate"
  exit
fi

i=0
geo=''
uniqid=''
environ=''
func=''

# In this section, we'll generate a bunch of names that have variable
# components.  What is used in those components will be randomly selected.
# Names will be func-environment-uniqueID.geo.example.com

select_func () {
# This function selects a random function of system from the predefined list
# included below.

rand=$(( ( RANDOM % 9 ) +1 ))

case $rand in
  1)
  func="web"
  ;;
  2)
  func="db"
  ;;
  3)
  func="appsrv"
  ;;
  4)
  func="ha"
  ;;
  5)
  func="mx"
  ;;
  6)
  func="sec"
  ;;
  7)
  func="cth"
  ;;
  8)
  func="vmh"
  ;;
  9)
  func="stor"
  ;;
esac
}

select_environment () {
# This function selects a random 'environment' for a server to live in

rand=$(( ( RANDOM % 4 ) +1 ))

case $rand in
  1)
  environ="dev"
  ;;
  2)
  environ="prod"
  ;;
  3)
  environ="qa"
  ;;
  4)
  environ="stg"
  ;;
esac
}

select_geo () {
# This function selects a random 'geography', based on a predetermined list
# of airport codes included in the function.

rand=$(( ( RANDOM % 10 ) +1 ))

case $rand in
  1)
    geo="atl"
  ;;
  2)
    geo="lax"
  ;;
  3)
    geo="ord"
  ;;
  4)
    geo="dbx"
  ;;
  5)
    geo="hnd"
  ;;
  6)
    geo="lhr"
  ;;
  7)
    geo="pvg"
  ;;
  8)
    geo="cdg"
  ;;
  9)
    geo="dfw"
  ;;
  10)
    geo="ams"
  ;;
esac
}

while [[ $i -lt $1 ]]
do
  uniqid=$(uuidgen | cut -c1-4)

  select_geo
  select_environment
  select_func

  echo "$func-$environ-$uniqid.$geo.example.com"

  (( i +=1 ))
done
