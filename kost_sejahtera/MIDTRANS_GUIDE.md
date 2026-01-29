# Midtrans Payment Gateway Integration Guide

## Backend Setup (Node.js + Express)

### 1. Install Dependencies

```bash
npm install express midtrans-client cors dotenv
```

### 2. Create Backend Server

Create `server.js`:

```javascript
const express = require('express');
const midtransClient = require('midtrans-client');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Midtrans Configuration
const snap = new midtransClient.Snap({
  isProduction: false, // Change to true for production
  serverKey: process.env.MIDTRANS_SERVER_KEY,
  clientKey: process.env.MIDTRANS_CLIENT_KEY
});

// Create Transaction
app.post('/api/payments/create-transaction', async (req, res) => {
  try {
    const { order_id, gross_amount, customer_details, payment_method } = req.body;

    const parameter = {
      transaction_details: {
        order_id: order_id,
        gross_amount: gross_amount
      },
      customer_details: customer_details,
      enabled_payments: getEnabledPayments(payment_method)
    };

    const transaction = await snap.createTransaction(parameter);
    
    res.json({
      token: transaction.token,
      redirect_url: transaction.redirect_url
    });
  } catch (error) {
    console.error('Error creating transaction:', error);
    res.status(500).json({ error: error.message });
  }
});

// Check Payment Status
app.get('/api/payments/status/:orderId', async (req, res) => {
  try {
    const { orderId } = req.params;
    const status = await snap.transaction.status(orderId);
    res.json(status);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Midtrans Webhook
app.post('/api/payments/webhook', async (req, res) => {
  try {
    const notification = req.body;
    
    // Verify notification
    const statusResponse = await snap.transaction.notification(notification);
    
    const orderId = statusResponse.order_id;
    const transactionStatus = statusResponse.transaction_status;
    const fraudStatus = statusResponse.fraud_status;

    console.log(`Transaction notification received. Order ID: ${orderId}. Transaction status: ${transactionStatus}. Fraud status: ${fraudStatus}`);

    // Update database based on transaction status
    if (transactionStatus == 'capture') {
      if (fraudStatus == 'challenge') {
        // TODO: Set transaction status to 'challenge'
      } else if (fraudStatus == 'accept') {
        // TODO: Set transaction status to 'success'
        updateInvoiceStatus(orderId, 'paid');
      }
    } else if (transactionStatus == 'settlement') {
      // TODO: Set transaction status to 'success'
      updateInvoiceStatus(orderId, 'paid');
    } else if (transactionStatus == 'cancel' || transactionStatus == 'deny' || transactionStatus == 'expire') {
      // TODO: Set transaction status to 'failed'
      updateInvoiceStatus(orderId, 'failed');
    } else if (transactionStatus == 'pending') {
      // TODO: Set transaction status to 'pending'
      updateInvoiceStatus(orderId, 'pending');
    }

    res.status(200).send('OK');
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).json({ error: error.message });
  }
});

function getEnabledPayments(method) {
  const paymentMethods = {
    'bank_transfer': ['bank_transfer'],
    'ewallet': ['gopay', 'shopeepay'],
    'qris': ['qris'],
  };
  return paymentMethods[method] || ['bank_transfer', 'gopay', 'shopeepay', 'qris'];
}

async function updateInvoiceStatus(orderId, status) {
  // TODO: Update invoice status in Firestore
  console.log(`Updating invoice ${orderId} to ${status}`);
}

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### 3. Environment Variables

Create `.env`:

```env
MIDTRANS_SERVER_KEY=SB-Mid-server-YOUR_SERVER_KEY
MIDTRANS_CLIENT_KEY=SB-Mid-client-YOUR_CLIENT_KEY
PORT=3000
```

### 4. Run Server

```bash
node server.js
```

## Flutter Integration

### 1. Update payment_service.dart

Replace the base URL with your backend URL:

```dart
final String _baseUrl = 'http://your-backend-url.com/api';
```

### 2. Use WebView for Payment

Install webview package:

```bash
flutter pub add webview_flutter
```

Create payment webview screen:

```dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  
  const PaymentWebView({Key? key, required this.paymentUrl}) : super(key: key);

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            // Check if payment is complete
            if (url.contains('finish') || url.contains('success')) {
              Navigator.pop(context, 'success');
            } else if (url.contains('error') || url.contains('failed')) {
              Navigator.pop(context, 'failed');
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pembayaran')),
      body: WebViewWidget(controller: controller),
    );
  }
}
```

## Testing

### Sandbox Credentials

Use these test cards for sandbox:

**Credit Card:**
- Card Number: `4811 1111 1111 1114`
- CVV: `123`
- Exp: Any future date

**GoPay:**
- Use any phone number
- OTP: `123456`

**Virtual Account:**
- Will generate test VA number
- Use Midtrans simulator to complete payment

## Production Deployment

1. Change `isProduction` to `true` in backend
2. Replace sandbox keys with production keys
3. Setup webhook URL in Midtrans dashboard
4. Deploy backend to cloud (Heroku, Railway, etc.)
5. Update Flutter app with production backend URL

## Webhook URL Setup

In Midtrans Dashboard:
1. Go to Settings → Configuration
2. Set Payment Notification URL: `https://your-backend-url.com/api/payments/webhook`
3. Save configuration

## Security Notes

- Never expose server key in Flutter app
- Always validate webhook notifications
- Use HTTPS in production
- Implement proper error handling
- Log all transactions for audit
