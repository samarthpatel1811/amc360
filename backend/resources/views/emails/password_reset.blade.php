<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Your AMC360 Password</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: #f1f5f9;
            margin: 0;
            padding: 24px;
            color: #1e293b;
        }
        .container {
            max-width: 520px;
            margin: 0 auto;
            background: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
            border: 1px solid #e2e8f0;
        }
        .header {
            background: linear-gradient(135deg, #1e3a8a 0%, #2563eb 100%);
            padding: 32px 24px;
            text-align: center;
            color: #ffffff;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
            font-weight: 800;
            letter-spacing: 0.5px;
        }
        .header p {
            margin: 6px 0 0 0;
            font-size: 13px;
            color: #bfdbfe;
        }
        .body {
            padding: 32px 28px;
        }
        .greeting {
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 12px;
            color: #0f172a;
        }
        .text {
            font-size: 14px;
            line-height: 1.6;
            color: #475569;
            margin-bottom: 24px;
        }
        .code-box {
            background: #f8fafc;
            border: 2px dashed #2563eb;
            border-radius: 12px;
            padding: 20px;
            text-align: center;
            margin: 24px 0;
        }
        .code-label {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            color: #64748b;
            font-weight: 700;
            margin-bottom: 8px;
        }
        .code {
            font-size: 34px;
            font-weight: 800;
            letter-spacing: 8px;
            color: #1e3a8a;
            font-family: 'Courier New', Courier, monospace;
        }
        .expiry {
            font-size: 12px;
            color: #dc2626;
            font-weight: 500;
            margin-top: 8px;
        }
        .warning-box {
            background: #fef2f2;
            border-left: 4px solid #ef4444;
            padding: 12px 16px;
            border-radius: 6px;
            font-size: 12px;
            color: #991b1b;
            line-height: 1.5;
            margin-top: 20px;
        }
        .footer {
            background: #f8fafc;
            padding: 20px 24px;
            text-align: center;
            font-size: 12px;
            color: #94a3b8;
            border-top: 1px solid #e2e8f0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>AMC360</h1>
            <p>Annual Maintenance Contract & Asset Management Platform</p>
        </div>
        <div class="body">
            <div class="greeting">Hello {{ $name }},</div>
            <div class="text">
                We received a request to reset your password for your AMC360 account. Please use the 6-digit verification code below to complete the reset process:
            </div>

            <div class="code-box">
                <div class="code-label">Verification Code</div>
                <div class="code">{{ $code }}</div>
                <div class="expiry">Expires in 15 minutes</div>
            </div>

            <div class="warning-box">
                <strong>Security Alert:</strong> If you did not request this password reset, please ignore this email. Your current password remains completely secure.
            </div>
        </div>
        <div class="footer">
            &copy; {{ date('Y') }} AMC360 Platform. All rights reserved.
        </div>
    </div>
</body>
</html>
