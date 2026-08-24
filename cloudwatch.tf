
resource "aws_sns_topic" "alerts" {
  name = "app-alerts-topic"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "palashdangat.sit.it@gmail.com"   # apna real email daal
}


resource "aws_cloudwatch_event_rule" "alarm_state_change" {
  name        = "alarm-state-change-rule"
  description = "Trigger jab koi CloudWatch alarm ALARM state mein jaaye"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      state = {
        value = ["ALARM"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.alarm_state_change.name
  target_id = "send-to-sns"
  arn       = aws_sns_topic.alerts.arn
}

resource "aws_sns_topic_policy" "allow_eventbridge" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridgePublish"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "SNS:Publish"
      Resource  = aws_sns_topic.alerts.arn
    }]
  })
}

resource "aws_cloudwatch_metric_alarm" "asg_high_cpu" {
  alarm_name          = "asg-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "ASG instances CPU 85% se zyada hai"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "rds-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU 80% se zyada hai"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.app_db.id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "rds-low-storage-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2000000000
  alarm_description   = "RDS storage 2GB se kam bacha hai"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.app_db.id
  }
}