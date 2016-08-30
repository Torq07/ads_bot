#!/bin/bash
while sleep 30
do
if pgrep -f /home/ubuntu/ads_bot/bin/bot >/dev/null
then
        echo 'Yaaya' >/dev/null
else
        ruby /home/ubuntu/ads_bot/bin/bot 2>/home/ubuntu/ads_bot/bot.log &! >/dev/null
fi
done

