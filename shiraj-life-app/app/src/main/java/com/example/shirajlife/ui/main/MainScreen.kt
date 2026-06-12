package com.example.shirajlife.ui.main

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.view.ViewGroup
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.navigation3.runtime.NavKey

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun MainScreen(
  onItemClick: (NavKey) -> Unit,
  modifier: Modifier = Modifier,
) {
  var canGoBack by remember { mutableStateOf(false) }
  var webViewRef by remember { mutableStateOf<WebView?>(null) }
  var progressState by remember { mutableStateOf(0) }
  var isPageLoading by remember { mutableStateOf(true) }

  // Intercept system back button presses to navigate back inside WebView
  BackHandler(enabled = canGoBack) {
    webViewRef?.goBack()
  }

  Box(
    modifier = Modifier
      .fillMaxSize()
      .background(Color(0xFF0D1012)) // Dark mode background match
  ) {
    AndroidView(
      factory = { context ->
        WebView(context).apply {
          layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
          )
          
          // WebView Settings
          settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            useWideViewPort = true
            loadWithOverviewMode = true
            cacheMode = WebSettings.LOAD_DEFAULT
            userAgentString = "$userAgentString ShirajLifeAndroidWrapper"
          }

          webViewClient = object : WebViewClient() {
            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
              super.onPageStarted(view, url, favicon)
              isPageLoading = true
            }

            override fun onPageFinished(view: WebView?, url: String?) {
              super.onPageFinished(view, url)
              isPageLoading = false
              canGoBack = view?.canGoBack() ?: false
            }

            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
              val url = request?.url?.toString() ?: ""
              // Keep browsing inside WebView for core site domains
              if (url.contains("shirajlife.com") || url.contains("localhost") || url.startsWith("file:///")) {
                return false
              }
              // Allow system app integrations for protocols (tel, mailto, maps, etc.)
              return false
            }
          }

          webChromeClient = object : WebChromeClient() {
            override fun onProgressChanged(view: WebView?, newProgress: Int) {
              super.onProgressChanged(view, newProgress)
              progressState = newProgress
              if (newProgress == 100) {
                isPageLoading = false
              }
            }
          }

          // Launch the live website landing page
          loadUrl("https://shirajlife.com")
          webViewRef = this
        }
      },
      modifier = Modifier.fillMaxSize()
    )

    // Sleek progress bar showing website load status
    AnimatedVisibility(
      visible = isPageLoading,
      enter = fadeIn(),
      exit = fadeOut(),
      modifier = Modifier.align(Alignment.TopCenter)
    ) {
      LinearProgressIndicator(
        progress = { progressState / 100f },
        modifier = Modifier
          .fillMaxWidth()
          .height(3.dp),
        color = Color(0xFF13B8A6), // Premium Teal Color
        trackColor = Color(0x2213B8A6)
      )
    }
  }
}
