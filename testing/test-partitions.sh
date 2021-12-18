#! /bin/bash

BASE_URL=$1
set -e -E -o pipefail
source `dirname $0`/common.sh

user_login_coordinator

`dirname $0`/reset-database.sh "$BASE_URL"
curl_postj action.php "action=racer.import&firstname=Kristie&lastname=Kyzer" | check_jsuccess
curl_postj action.php "action=racer.import&firstname=Shana&lastname=Sester" | check_jsuccess
curl_postj action.php "action=racer.import&firstname=Glendora&lastname=Giusti" | check_jsuccess
curl_postj action.php "action=racer.import&firstname=Ophelia&lastname=Oja" | check_jsuccess
curl_postj action.php "action=racer.import&firstname=Mirna&lastname=Manier" | check_jsuccess

curl_getj "action.php?query=poll&values=partitions" | \
    jq -e '.partitions | length == 1 and .[0].name == "Default"' >/dev/null || test_fails

`dirname $0`/reset-database.sh "$BASE_URL"
`dirname $0`/import-divided-roster.sh "$BASE_URL"

curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 3 
        and .[0].name == "Default" and .[0].classid == 1
        and (.[0].subgroups | length == 1)
        and .[0].subgroups[0].name == "Default"
        and .[0].subgroups[0].rankid == 1
        and .[1].name == "Div 2" and .[1].classid == 2
        and (.[1].subgroups | length == 1)
        and .[1].subgroups[0].name == "Div 2"
        and .[1].subgroups[0].rankid == 2
        and .[2].name == "Div 3" and .[2].classid == 3
        and (.[2].subgroups | length == 1)
        and .[2].subgroups[0].name == "Div 3"
        and .[2].subgroups[0].rankid == 3
' >/dev/null || test_fails

# With by-partition rule, reordering classes should reorder partitions
curl_postj action.php "action=class.order&classid_1=2&classid_2=1&classid_3=3" | check_jsuccess
curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 3 
        and .[0].name == "Div 2" and .[0].classid == 2
        and (.[0].subgroups | length == 1)
        and .[0].subgroups[0].name == "Div 2"
        and .[0].subgroups[0].rankid == 2
        and .[1].name == "Default" and .[1].classid == 1
        and (.[1].subgroups | length == 1)
        and .[1].subgroups[0].name == "Default"
        and .[1].subgroups[0].rankid == 1
        and .[2].name == "Div 3" and .[2].classid == 3
        and (.[2].subgroups | length == 1)
        and .[2].subgroups[0].name == "Div 3"
        and .[2].subgroups[0].rankid == 3
' >/dev/null || test_fails

curl_getj "action.php?query=poll&values=partitions" | \
    jq -e '.partitions | length == 3 
        and .[0].name == "Div 2" and .[0].partitionid == 2 and .[0].count == 19
        and .[1].name == "Default" and .[1].partitionid == 1 and .[1].count == 20
        and .[2].name == "Div 3" and .[2].partitionid == 3 and .[2].count == 10
' >/dev/null || test_fails

curl_postj action.php "action=partition.apply-rule&rule=one-group" | check_jsuccess

curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 1
        and .[0].name == "One Group" and .[0].count == 49 and (.[0].subgroups | length == 3)
        and .[0].subgroups[0].name == "Div 2"
        and .[0].subgroups[0].rankid == 2
        and .[0].subgroups[0].count == 19
        and .[0].subgroups[1].name == "Default"
        and .[0].subgroups[1].rankid == 1
        and .[0].subgroups[1].count == 20
        and .[0].subgroups[2].name == "Div 3"
        and .[0].subgroups[2].rankid == 3
        and .[0].subgroups[2].count == 10
' >/dev/null || test_fails

# With one-group rule, reordering subdgroups should reorder partitions
curl_postj action.php "action=rank.order&rankid_1=1&rankid_2=2&rankid_3=3" | check_jsuccess
curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 1
        and .[0].name == "One Group" and (.[0].subgroups | length == 3)
        and .[0].subgroups[0].name == "Default"
        and .[0].subgroups[0].rankid == 1
        and .[0].subgroups[1].name == "Div 2"
        and .[0].subgroups[1].rankid == 2
        and .[0].subgroups[2].name == "Div 3"
        and .[0].subgroups[2].rankid == 3
' >/dev/null || test_fails
curl_getj "action.php?query=poll&values=partitions" | \
    jq -e '.partitions | length == 3 
        and .[0].name == "Default" and .[0].partitionid == 1
        and .[1].name == "Div 2" and .[1].partitionid == 2
        and .[2].name == "Div 3" and .[2].partitionid == 3
' >/dev/null || test_fails


curl_postj action.php "action=partition.apply-rule&rule=by-partition" | check_jsuccess

curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 3 
        and .[0].name == "Default" and .[0].count == 20 and (.[0].subgroups | length == 1)
        and .[0].subgroups[0].name == "Default"
        and .[1].name == "Div 2" and .[1].count == 19 and (.[1].subgroups | length == 1)
        and .[1].subgroups[0].name == "Div 2"
        and .[2].name == "Div 3" and .[2].count == 10 and (.[2].subgroups | length == 1)
        and .[2].subgroups[0].name == "Div 3"
' >/dev/null || test_fails

curl_postj action.php "action=partition.apply-rule&rule=custom" | check_jsuccess

curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 3 
        and .[0].name == "Default" and .[0].count == 20 and (.[0].subgroups | length == 1)
        and .[0].subgroups[0].name == "Default"
        and .[0].subgroups[0].count == 20
        and .[0].subgroups[0].rankid == 1
        and .[1].name == "Div 2"
        and (.[1].subgroups | length == 1)
        and .[1].subgroups[0].name == "Div 2"
        and .[1].subgroups[0].count == 19
        and .[1].subgroups[0].rankid == 2
        and .[2].name == "Div 3"
        and (.[2].subgroups | length == 1)
        and .[2].subgroups[0].name == "Div 3"
        and .[2].subgroups[0].count == 10
        and .[2].subgroups[0].rankid == 3
' >/dev/null || test_fails

curl_postj action.php "action=partition.move&div_id=3&group_field=classid&group_id=1" | check_jsuccess

curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 3 
        and .[0].name == "Default" and (.[0].subgroups | length == 2)
        and .[0].subgroups[0].name == "Default"
        and .[0].subgroups[0].count == 20
        and .[0].subgroups[0].rankid == 1
        and .[0].subgroups[1].name == "Div 3"
        and .[0].subgroups[1].count == 10
        and .[0].subgroups[1].rankid == 4
        and .[1].name == "Div 2" and (.[1].subgroups | length == 1)
        and .[1].subgroups[0].name == "Div 2"
        and .[1].subgroups[0].count == 19
        and .[1].subgroups[0].rankid == 2
        and .[2].name == "Div 3" and (.[2].subgroups | length == 1)
        and .[2].subgroups[0].name == "Div 3"
        and .[2].subgroups[0].count == 0
        and .[2].subgroups[0].rankid == 3
' >/dev/null || test_fails

curl_getj "action.php?query=poll&values=partitions" | \
    jq -e '.partitions | length == 3
        and .[0].name == "Default"
        and .[1].name == "Div 3"
        and .[2].name == "Div 2"
' >/dev/null || test_fails

curl_postj action.php "action=partition.apply-rule&rule=custom&cleanup=1" | check_jsuccess

curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 2
        and .[0].name == "Default" and (.[0].subgroups | length == 2)
        and .[0].subgroups[0].name == "Default"
        and .[0].subgroups[0].count == 20
        and .[0].subgroups[0].rankid == 1
        and .[0].subgroups[1].name == "Div 3"
        and .[0].subgroups[1].count == 10
        and .[0].subgroups[1].rankid == 4
        and .[1].name == "Div 2" and (.[1].subgroups | length == 1)
        and .[1].subgroups[0].name == "Div 2"
        and .[1].subgroups[0].count == 19
        and .[1].subgroups[0].rankid == 2
' >/dev/null || test_fails

curl_postj action.php "action=partition.move&div_id=3&group_field=classid&group_id=-1" | check_jsuccess

curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 3
        and .[0].name == "Default" and (.[0].subgroups | length == 2)
        and .[0].subgroups[0].name == "Default" and .[0].subgroups[0].rankid == 1
        and .[0].subgroups[1].name == "Div 3" and .[0].subgroups[1].rankid == 4
            and .[0].subgroups[1].count == 0
        and .[1].name == "Div 2" and (.[1].subgroups | length == 1)
        and .[1].subgroups[0].name == "Div 2" and .[1].subgroups[0].rankid == 2
        and .[2].name == "Div 3" and (.[2].subgroups | length == 1)
        and .[2].subgroups[0].name == "Div 3" and .[2].subgroups[0].rankid == 5
            and .[2].subgroups[0].count == 10
' >/dev/null || test_fails
curl_getj "action.php?query=poll&values=partitions" | \
    jq -e '.partitions | length == 3
        and .[0].name == "Default"
        and .[1].name == "Div 2"
        and .[2].name == "Div 3"
' >/dev/null || test_fails

curl_postj action.php "action=partition.apply-rule&rule=by-partition" | check_jsuccess
curl_getj "action.php?query=poll&values=partitions" | \
    jq -e '.partitions | length == 3
        and .[0].name == "Default"
        and .[1].name == "Div 2"
        and .[2].name == "Div 3"
' >/dev/null || test_fails
curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 3
        and .[0].name == "Default"
        and .[1].name == "Div 2"
        and .[2].name == "Div 3"
' >/dev/null || test_fails

curl_postj action.php "action=partition.order&partitionid_1=3&partitionid_2=2&partitionid_3=1" | check_jsuccess
curl_getj "action.php?query=poll&values=partitions" | \
    jq -e '.partitions | length == 3
        and .[0].name == "Div 3" and .[0].partitionid == 3
        and .[1].name == "Div 2" and .[1].partitionid == 2
        and .[2].name == "Default" and .[2].partitionid == 1
' >/dev/null || test_fails
curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 3
        and .[0].name == "Div 3"
        and .[1].name == "Div 2"
        and .[2].name == "Default"
' >/dev/null || test_fails

curl_postj action.php "action=partition.apply-rule&rule=one-group" | check_jsuccess
curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 1
        and .[0].name == "One Group"
        and (.[0].subgroups | length == 3)
        and .[0].subgroups[0].name == "Div 3"
        and .[0].subgroups[1].name == "Div 2"
        and .[0].subgroups[2].name == "Default"
' >/dev/null || test_fails
curl_postj action.php "action=partition.order&partitionid_1=2&partitionid_2=3&partitionid_3=1" | check_jsuccess
curl_getj "action.php?query=poll&values=partitions" | \
    jq -e '.partitions | length == 3
        and .[0].name == "Div 2" and .[0].partitionid == 2
        and .[1].name == "Div 3" and .[1].partitionid == 3
        and .[2].name == "Default" and .[2].partitionid == 1
' >/dev/null || test_fails
curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 1
        and .[0].name == "One Group"
        and (.[0].subgroups | length == 3)
        and .[0].subgroups[0].name == "Div 2"
        and .[0].subgroups[1].name == "Div 3"
        and .[0].subgroups[2].name == "Default"
' >/dev/null || test_fails

curl_postj action.php "action=partition.edit&partitionid=1&name=Div%202" | check_jfailure
curl_postj action.php "action=partition.edit&partitionid=1&name=Default" | check_jsuccess # no-op
curl_postj action.php "action=partition.edit&partitionid=1&name=Div%201" | check_jsuccess
curl_getj "action.php?query=poll&values=partitions" | \
    jq -e '.partitions | length == 3
        and .[0].name == "Div 2" and .[0].partitionid == 2
        and .[1].name == "Div 3" and .[1].partitionid == 3
        and .[2].name == "Div 1" and .[2].partitionid == 1
' >/dev/null || test_fails
curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 1
        and .[0].name == "One Group"
        and (.[0].subgroups | length == 3)
        and .[0].subgroups[0].name == "Div 2"
        and .[0].subgroups[1].name == "Div 3"
        and .[0].subgroups[2].name == "Div 1"
' >/dev/null || test_fails

curl_postj action.php "action=partition.add&name=Div%201" | check_jfailure
curl_postj action.php "action=partition.add&name=New%20Div" | check_jsuccess
curl_getj "action.php?query=poll&values=partitions" | \
    jq -e '.partitions | length == 4
        and .[0].name == "Div 2" and .[0].partitionid == 2
        and .[1].name == "Div 3" and .[1].partitionid == 3
        and .[2].name == "Div 1" and .[2].partitionid == 1
        and .[3].name == "New Div" and .[3].partitionid == 4
' >/dev/null || test_fails
curl_getj "action.php?query=poll&values=classes" | \
    jq -e '.classes | length == 1
        and .[0].name == "One Group"
        and (.[0].subgroups | length == 4)
        and .[0].subgroups[0].name == "Div 2"
        and .[0].subgroups[1].name == "Div 3"
        and .[0].subgroups[2].name == "Div 1"
        and .[0].subgroups[3].name == "New Div"
' >/dev/null || test_fails


# 'by-partition', then 'custom'
curl_postj action.php "action=partition.apply-rule&rule=by-partition" | check_jsuccess
curl_postj action.php "action=partition.apply-rule&rule=custom&cleanup=1" | check_jsuccess

# Move partition 2 to the class already containing partition 1.  That should
# leave partition 2's original class empty, and so removed by cleanup.
curl_getj "action.php?query=poll&values=partitions" > /dev/null
P1CLASSID=$(jq '.partitions | map(select(.partitionid==1))[0].classids[0]' $DEBUG_CURL)
P2CLASSID=$(jq '.partitions | map(select(.partitionid==2))[0].classids[0]' $DEBUG_CURL)
curl_getj "action.php?query=poll&values=rounds" > /dev/null
P1ROSTERSIZE=$(jq ".rounds | map(select(.classid==$P1CLASSID))[0].roster_size" $DEBUG_CURL)
P2ROSTERSIZE=$(jq ".rounds | map(select(.classid==$P2CLASSID))[0].roster_size" $DEBUG_CURL)

curl_postj action.php "action=partition.move&div_id=2&group_field=classid&group_id=$P1CLASSID&cleanup=1" | \
    check_jsuccess
# Confirm that old class for partition 2 got cleaned up
curl_getj "action.php?query=poll&values=classes" | \
    jq -e ".classes | map(select(.classid==$P2CLASSID)) | length == 0" > /dev/null || test_fails
# Confirm that the moved racers are included in the roster for $P1CLASSID
let NEW_P1ROSTERSIZE=$P1ROSTERSIZE+$P2ROSTERSIZE
curl_getj "action.php?query=poll&values=rounds" | \
    jq -e ".rounds | map(select(.classid==$P1CLASSID))[0].roster_size == $NEW_P1ROSTERSIZE" \
       > /dev/null || test_fails

# Move the partition again, now to a new group: group_field = 'classid', group_id = -1;
# check that the racers appear in a roster for the new class.
curl_postj action.php "action=partition.move&div_id=2&group_field=classid&group_id=-1&cleanup=1" | \
    check_jsuccess
curl_getj "action.php?query=poll&values=partitions" > /dev/null
P2XCLASSID=$(jq '.partitions | map(select(.partitionid==2))[0].classids[0]' $DEBUG_CURL)
curl_getj "action.php?query=poll&values=rounds" | \
    jq -e ".rounds | map(select(.classid==$P1CLASSID))[0].roster_size == $P1ROSTERSIZE" \
       > /dev/null || test_fails
curl_getj "action.php?query=poll&values=rounds" | \
    jq -e ".rounds | map(select(.classid==$P2XCLASSID))[0].roster_size == $P2ROSTERSIZE" \
       > /dev/null || test_fails

curl_postj action.php "action=partition.apply-rule&rule=by-partition" | check_jsuccess
curl_getj "action.php?query=poll&values=partitions" > /dev/null
# New classes makes potentially new classids for the partitions
P1CLASSID=$(jq '.partitions | map(select(.partitionid==1))[0].classids[0]' $DEBUG_CURL)
P2CLASSID=$(jq '.partitions | map(select(.partitionid==2))[0].classids[0]' $DEBUG_CURL)
# Confirm rosters are as expected
curl_getj "action.php?query=poll&values=rounds" | \
    jq -e ".rounds | map(select(.classid==$P1CLASSID))[0].roster_size == $P1ROSTERSIZE" \
       > /dev/null || test_fails
curl_getj "action.php?query=poll&values=rounds" | \
    jq -e ".rounds | map(select(.classid==$P2CLASSID))[0].roster_size == $P2ROSTERSIZE" \
       > /dev/null || test_fails


# Move all the "Div 3" racers to "New Div", then delete "Div 3"
for RACERID in 5 10 15 20 25 30 35 40 45 49; do
    curl_postj action.php "action=racer.edit&racerid=$RACERID&partitionid=4" | check_jsuccess
done
curl_postj action.php "action=partition.delete&partitionid=3" | check_jsuccess

