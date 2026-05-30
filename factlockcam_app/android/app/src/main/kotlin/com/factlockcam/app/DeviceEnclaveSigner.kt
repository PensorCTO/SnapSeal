package com.factlockcam.app

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.util.Base64

object DeviceEnclaveSigner {
  private const val alias = "com.factlockcam.device_signing"

  fun signHash(context: Context, hex: String): String {
    val digest = digestFromHex(hex)
    val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    if (!keyStore.containsAlias(alias)) {
      generateKey(context)
    }
    val entry = keyStore.getEntry(alias, null) as KeyStore.PrivateKeyEntry
    val signature = Signature.getInstance("SHA256withECDSA")
    signature.initSign(entry.privateKey)
    signature.update(digest)
    return Base64.getEncoder().encodeToString(signature.sign())
  }

  private fun generateKey(context: Context) {
    val builder =
      KeyGenParameterSpec.Builder(
        alias,
        KeyProperties.PURPOSE_SIGN,
      )
        .setDigests(KeyProperties.DIGEST_SHA256)
        .setAlgorithmParameterSpec(java.security.spec.ECGenParameterSpec("secp256r1"))
        .setUserAuthenticationRequired(false)

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
      context.packageManager.hasSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE)
    ) {
      builder.setIsStrongBoxBacked(true)
    }

    val generator = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore")
    generator.initialize(builder.build())
    generator.generateKeyPair()
  }

  private fun digestFromHex(hex: String): ByteArray {
    val trimmed = hex.trim().lowercase()
    require(trimmed.isNotEmpty() && trimmed.length % 2 == 0) { "hash must be non-empty hex" }
    return trimmed.chunked(2).map { it.toInt(16).toByte() }.toByteArray()
  }
}
