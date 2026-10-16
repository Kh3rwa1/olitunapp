package com.ol.itun

import android.os.Bundle
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceFragmentActivity

class MainActivity : AudioServiceFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Edge-to-edge on every API level. Transparent system bars and the
        // display-cutout mode live in the themes (values*/styles.xml), so no
        // Android 15-deprecated Window color or cutout calls are made here
        // (androidx enableEdgeToEdge() still calls setStatusBarColor and
        // setNavigationBarColor on older APIs).
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
