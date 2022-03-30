#!/bin/bash
time=60

#Store Topic Message
while true; do
    gcloud pubsub subscriptions pull subscription-demo1 --format=json
        for pubsub in $(gcloud pubsub subscriptions pull subscription-demo1 --format=json)
        do
            sudo touch output.json && echo $pubsub >> output.json
            sudo mv output.json /
        done
    gsutil cp output.json gs://bucket-rbarrientos1-demo/
    sleep  $time;
done