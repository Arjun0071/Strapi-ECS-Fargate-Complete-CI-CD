resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "strapi-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.strapi_service.name
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_mem_high" {
  alarm_name          = "strapi-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.strapi_service.name
  }
}

# -----------------------------
# ECS Task Health Alarm (via ALB)
# -----------------------------
resource "aws_cloudwatch_metric_alarm" "ecs_task_unhealthy" {
  alarm_name          = "strapi-ecs-task-unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
    TargetGroup  = aws_lb_target_group.tg.arn_suffix
  }
}

# -----------------------------
# Application Response Latency Alarm (via ALB)
# -----------------------------
resource "aws_cloudwatch_metric_alarm" "ecs_target_latency_high" {
  alarm_name          = "strapi-ecs-target-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 2   # seconds, adjust as needed

  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
    TargetGroup  = aws_lb_target_group.tg.arn_suffix
  }
}

# -----------------------------
# Optional CloudWatch Dashboard
# -----------------------------
resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
  dashboard_name = "strapi-ecs-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.cluster.name, "ServiceName", aws_ecs_service.strapi_service.name ],
            [ "AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.cluster.name, "ServiceName", aws_ecs_service.strapi_service.name ],
            [ "AWS/ApplicationELB", "UnhealthyHostCount", "LoadBalancer", aws_lb.alb.arn_suffix, "TargetGroup", aws_lb_target_group.tg.arn_suffix ],
            [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.alb.arn_suffix, "TargetGroup", aws_lb_target_group.tg.arn_suffix ]
          ]
          period = 60
          title  = "Strapi ECS & ALB Metrics"
        }
      }
    ]
  })
}
