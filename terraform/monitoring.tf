# ----------------------------------------------------------------------------------------------------------------------
# CloudWatch Dashboard
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name}-dashboard"
  dashboard_body = jsonencode({
    "widgets" : [
      {
        "height" : 10,
        "width" : 10,
        "y" : 0,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            [
              {
                "expression" : "SELECT SUM(RequestCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer)",
                "label" : "Query1",
                "id" : "q1"
              }
            ]
          ],
          "region" : "${var.region}",
          "stat" : "Average",
          "period" : 300,
          "title" : "ALB: Total Requests"
        }
      },
      {
        "height" : 10,
        "width" : 10,
        "y" : 0,
        "x" : 10,
        "type" : "metric",
        "properties" : {
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            [
              {
                "expression" : "SELECT MAX(ActiveConnectionCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer) GROUP BY LoadBalancer ORDER BY SUM() DESC LIMIT 10",
                "label" : "Query2",
                "id" : "q2"
              }
            ]
          ],
          "region" : "${var.region}",
          "stat" : "Average",
          "period" : 300,
          "title" : "ALB: Active Connections Count"
        }
      },
      {
        "height" : 10,
        "width" : 10,
        "y" : 10,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            [
              {
                "expression" : "SELECT SUM(Invocations) FROM SCHEMA(\"AWS/Lambda\",FunctionName) GROUP BY FunctionName ORDER BY SUM() DESC",
                "label" : "Query3",
                "id" : "q3"
              }
            ]
          ],
          "region" : "${var.region}",
          "stat" : "Average",
          "period" : 300,
          "title" : "Lambda: Number of Invocations"
        }
      },
      {
        "height" : 10,
        "width" : 10,
        "y" : 10,
        "x" : 10,
        "type" : "metric",
        "properties" : {
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            [
              {
                "expression" : "SELECT AVG(Duration) FROM SCHEMA(\"AWS/Lambda\",FunctionName) GROUP BY FunctionName ORDER BY MAX() DESC LIMIT 10",
                "label" : "Query4",
                "id" : "q4"
              }
            ]
          ],
          "region" : "${var.region}",
          "stat" : "Average",
          "period" : 300,
          "title" : "Lambda: Top 10 Longest Runtime Func"
        }
      },
      {
        "height" : 10,
        "width" : 10,
        "y" : 20,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            [
              {
                "expression" : "SELECT SUM(Errors) FROM SCHEMA(\"AWS/Lambda\", FunctionName) GROUP BY FunctionName ORDER BY SUM() DESC LIMIT 10",
                "label" : "Query5",
                "id" : "q5"
              }
            ]
          ],
          "region" : "${var.region}",
          "stat" : "Average",
          "period" : 300,
          "title" : "Lambda: Top 10 Error Count Func"
        }
      },
      {
        "height" : 10,
        "width" : 10,
        "y" : 20,
        "x" : 10,
        "type" : "metric",
        "properties" : {
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            [
              {
                "expression" : "SELECT AVG(CPUUtilization) FROM SCHEMA(\"AWS/EC2\", InstanceId) GROUP BY InstanceId ORDER BY AVG() DESC LIMIT 10",
                "label" : "Query6",
                "id" : "q6"
              }
            ]
          ],
          "region" : "${var.region}",
          "stat" : "Average",
          "period" : 300,
          "title" : "EC2: Top 10 Highest CPU util. instances"
        }
      },
      {
        "height" : 10,
        "width" : 10,
        "y" : 30,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            [
              {
                "expression" : "SELECT AVG(CPUUtilization) FROM SCHEMA(\"AWS/EC2\", InstanceId)",
                "label" : "Query7",
                "id" : "q7"
              }
            ]
          ],
          "region" : "${var.region}",
          "stat" : "Average",
          "period" : 300,
          "title" : "EC2: CPU across entire fleet"
        }
      },
      {
        "height" : 10,
        "width" : 10,
        "y" : 30,
        "x" : 10,
        "type" : "metric",
        "properties" : {
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            [
              {
                "expression" : "SELECT AVG(CPUUtilization) FROM SCHEMA(\"AWS/EC2\", InstanceId) GROUP BY InstanceId ORDER BY AVG() DESC",
                "label" : "Query8",
                "id" : "q8"
              }
            ]
          ],
          "region" : "${var.region}",
          "stat" : "Average",
          "period" : 300,
          "title" : "EC2: Highest utilization CPU instances"
        }
      },
      {
        "height" : 10,
        "width" : 10,
        "y" : 40,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            [
              {
                "expression" : "SELECT AVG(TotalRequestLatency) FROM SCHEMA(\"AWS/S3\", BucketName, FilterId) WHERE FilterId = 'EntireBucket' GROUP BY BucketName ORDER BY AVG() DESC",
                "label" : "Query9",
                "id" : "q9"
              }
            ]
          ],
          "region" : "${var.region}",
          "stat" : "Average",
          "period" : 300,
          "title" : "S3: Average latency by bucket"
        }
      },
      {
        "height" : 10,
        "width" : 10,
        "y" : 40,
        "x" : 10,
        "type" : "metric",
        "properties" : {
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            [
              {
                "expression" : "SELECT SUM(BytesDownloaded) FROM SCHEMA(\"AWS/S3\", BucketName, FilterId) WHERE FilterId = 'EntireBucket' GROUP BY BucketName ORDER BY SUM() DESC LIMIT 10",
                "label" : "Query10",
                "id" : "q10"
              }
            ]
          ],
          "region" : "${var.region}",
          "stat" : "Average",
          "period" : 300,
          "title" : "S3: Top 10 buckets"
        }
      },
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 15,
        "height" : 10,
        "properties" : {
          "metrics" : [
            ["WAF", "BlockedRequests", "WebACL", "WAFWebACLMetric", "Rule", "ALL", "Region", "${data.aws_region.current.name}"],
            ["WAF", "AllowedRequests", "WebACL", "WAFWebACLMetric", "Rule", "ALL", "Region", "${data.aws_region.current.name}"]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "stat" : "Sum",
          "period" : 300,
          "region" : "${data.aws_region.current.name}"
        }
      }
    ]
  })
}
