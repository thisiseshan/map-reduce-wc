# Makefile for Python Hadoop MapReduce Project

# Define paths and settings for local environment and AWS
# HADOOP_STREAMING_JAR=/opt/homebrew/bin/hadoop
HADOOP_STREAMING_JAR=/opt/homebrew/Cellar/hadoop//3.3.6/libexec/share/hadoop/tools/lib/hadoop-streaming-3.3.6.jar
HADOOP_ROOT=/opt/homebrew/bin/hadoop
LOCAL_INPUT_DIR=/Users/eshan/Documents/CS6240/hw1/input
LOCAL_OUTPUT_DIR=/Users/eshan/Documents/CS6240/hw1/output
LOCAL_OUTPUT_DIR_AWS=/Users/eshan/Documents/CS6240/hw1/output-aws
# AWS_BUCKET_NAME=super-cool-bucket
AWS_BUCKET_NAME=cs6240-demo-bucket-super-cool-bucket

AWS_INPUT_DIR=s3://$(AWS_BUCKET_NAME)/input
AWS_OUTPUT_DIR=s3://$(AWS_BUCKET_NAME)/output

# Define Python scripts
MAPPER=/Users/eshan/Documents/CS6240/hw1/src/mapper.py
REDUCER=/Users/eshan/Documents/CS6240/hw1/src/reducer.py

# AWS EMR Execution Settings
AWS_EMR_RELEASE=emr-6.10.0
AWS_REGION=us-east-1
# AWS_BUCKET_NAME=cs6240-demo-bucket-super-cool-bucket
AWS_SUBNET_ID=subnet-6356553a
# AWS_INPUT=input
# AWS_OUTPUT=output
AWS_INPUT_DIR=s3://$(AWS_BUCKET_NAME)/input
AWS_OUTPUT_DIR=s3://$(AWS_BUCKET_NAME)/output
AWS_LOG_DIR=log
AWS_NUM_NODES=1
AWS_INSTANCE_TYPE=m3.xlarge

##### Local execution baby! ####
local-standalone:
	hadoop jar $(HADOOP_STREAMING_JAR) \
		-file $(MAPPER) -mapper $(MAPPER) \
		-file $(REDUCER) -reducer $(REDUCER) \
		-input $(LOCAL_INPUT_DIR) -output $(LOCAL_OUTPUT_DIR)

# Clean local output
clean-local:
	rm -rf $(LOCAL_OUTPUT_DIR)/*


#### AWS #####
# Create S3 bucket
make-bucket:
	aws s3 mb s3://$(AWS_BUCKET_NAME)

# Upload data to S3 input directory
upload-input-aws: make-bucket
	aws s3 sync $(LOCAL_INPUT_DIR) $(AWS_INPUT_DIR)

# upload-map-reduce-files:
# 	aws s3 sync $(MAPPER) $(AWS_INPUT_DIR)
# 	aws s3 sync $(REDUCER) $(AWS_INPUT_DIR)

# Delete S3 output directory
delete-output-aws:
	aws s3 rm $(AWS_OUTPUT_DIR) --recursive


# AWS EMR execution
aws:
	aws emr create-cluster --name "Python MapReduce" \
		--release-label emr-6.10.0 \
		--region us-east-1 \
		--instance-groups '[{"InstanceCount":1,"InstanceGroupType":"MASTER","InstanceType":"m3.xlarge"},{"InstanceCount":2,"InstanceGroupType":"CORE","InstanceType":"m3.xlarge"}]' \
		--applications Name=Hadoop \
		--steps '[{"Args":["hadoop-streaming","-files","s3://cs6240-demo-bucket-super-cool-bucket/input/mapper.py,s3://cs6240-demo-bucket-super-cool-bucket/input/reducer.py","-mapper","s3://cs6240-demo-bucket-super-cool-bucket/input/mapper.py","-reducer","s3://cs6240-demo-bucket-super-cool-bucket/input/reducer.py","-input","s3://cs6240-demo-bucket-super-cool-bucket/input/hhg.txt","-output","s3://cs6240-demo-bucket-super-cool-bucket/output"],"Type":"CUSTOM_JAR","Jar":"command-runner.jar","ActionOnFailure":"TERMINATE_CLUSTER","Name":"MapReduce Job"}]' \
		--log-uri s3://cs6240-demo-bucket-super-cool-bucket/log \
		--use-default-roles \
		--auto-terminate



# aws:
# 	aws s3 rm $(AWS_OUTPUT_DIR) --recursive
# 	aws emr create-cluster --name "Python MapReduce" \
# 		--release-label emr-6.10.0 \
# 		--applications Name=Hadoop \
# 		--instance-groups '[{"InstanceCount":1,"InstanceGroupType":"MASTER","InstanceType":"m5.xlarge"},{"InstanceCount":2,"InstanceGroupType":"CORE","InstanceType":"m5.xlarge"}]' \
# 		--steps '[{"Args":["hadoop-streaming","-files","$(AWS_INPUT_DIR)/$(MAPPER),$(AWS_INPUT_DIR)/$(REDUCER)","-mapper","$(MAPPER)","-reducer","$(REDUCER)","-input","$(AWS_INPUT_DIR)/*","-output","$(AWS_OUTPUT_DIR)"],"Type":"CUSTOM_JAR","Jar":"command-runner.jar","ActionOnFailure":"TERMINATE_CLUSTER","Name":"MapReduce Job"}]' \
# 		--auto-terminate \
# 		--log-uri s3://$(AWS_BUCKET_NAME)/logs \
# 		--use-default-roles

# aws:
# 	aws s3 rm s3://$(AWS_BUCKET_NAME)/$(AWS_OUTPUT) --recursive
# 	aws emr create-cluster --name "Python MapReduce" \
# 		--release-label $(AWS_EMR_RELEASE) \
# 		--region $(AWS_REGION) \
# 		--instance-groups '[{"InstanceCount":$(AWS_NUM_NODES),"InstanceGroupType":"MASTER","InstanceType":"$(AWS_INSTANCE_TYPE)"},{"InstanceCount":2,"InstanceGroupType":"CORE","InstanceType":"$(AWS_INSTANCE_TYPE)"}]' \
# 		--applications Name=Hadoop \
# 		--steps '[{"Args":["hadoop-streaming","-files","$(AWS_INPUT_DIR)/mapper.py,$(AWS_INPUT_DIR)/reducer.py","-mapper","mapper.py","-reducer","reducer.py","-input","s3://$(AWS_BUCKET_NAME)/$(AWS_INPUT)/*","-output","s3://$(AWS_BUCKET_NAME)/$(AWS_OUTPUT_DIR)"],"Type":"CUSTOM_JAR","Jar":"command-runner.jar","ActionOnFailure":"TERMINATE_CLUSTER","Name":"MapReduce Job"}]' \
# 		--log-uri s3://$(AWS_BUCKET_NAME)/$(AWS_LOG_DIR) \
# 		--use-default-roles \
# 		--auto-terminate

# Update this part according to your AWS region and settings
aws-upload-input:
	aws s3 sync $(LOCAL_INPUT_DIR) $(AWS_INPUT_DIR)

download-output-aws:
	aws s3 sync $(AWS_OUTPUT_DIR) $(LOCAL_OUTPUT_DIR_AWS)





# # Start HDFS for pseudo-distributed mode
# start-hdfs:
# 	$(HADOOP_ROOT)/sbin/start-dfs.sh

# # Stop HDFS
# stop-hdfs: 
# 	$(HADOOP_ROOT)/sbin/stop-dfs.sh

# # Start YARN for pseudo-distributed mode
# start-yarn: stop-yarn
# 	$(HADOOP_ROOT)/sbin/start-yarn.sh

# # Stop YARN
# stop-yarn:
# 	$(HADOOP_ROOT)/sbin/stop-yarn.sh

# # Reformats & initializes HDFS for pseudo-distributed mode
# format-hdfs: stop-hdfs
# 	rm -rf /tmp/hadoop-${USER}*
# 	$(HADOOP_ROOT)/bin/hdfs namenode -format

# # Initializes user & input directories of HDFS for pseudo-distributed mode	
# init-hdfs: start-hdfs
# 	$(HADOOP_ROOT)/bin/hdfs dfs -rm -r -f /user
# 	$(HADOOP_ROOT)/bin/hdfs dfs -mkdir /user
# 	$(HADOOP_ROOT)/bin/hdfs dfs -mkdir /user/${USER}
# 	$(HADOOP_ROOT)/bin/hdfs dfs -mkdir /user/${USER}/input

# # Load data to HDFS for pseudo-distributed mode
# upload-input-hdfs: start-hdfs
# 	$(HADOOP_ROOT)/bin/hdfs dfs -put $(LOCAL_INPUT_DIR)/* /user/${USER}/input

# # Removes HDFS output directory in pseudo-distributed mode
# clean-hdfs-output:
# 	$(HADOOP_ROOT)/bin/hdfs dfs -rm -r -f output*

# # Runs MapReduce job in pseudo-distributed mode
# pseudo: local-standalone stop-yarn format-hdfs init-hdfs upload-input-hdfs start-yarn clean-local 
# 	hadoop jar $(HADOOP_STREAMING_JAR) \
# 		-file $(MAPPER) -mapper $(MAPPER) \
# 		-file $(REDUCER) -reducer $(REDUCER) \
# 		-input input -output output
# 	# Add commands to download output from HDFS if needed

