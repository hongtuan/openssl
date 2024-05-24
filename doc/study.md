# openssl 源码研究
## 术语
以下术语按字母顺序在本文中使用，简要定义如下：
- 算法（Algorithm）：有时称为密码算法，是执行一组操作（如加密或解密）的方法。我们使用这个术语时是抽象的，通常通过名称（例如“aes-128-cbc”）来表示一个算法。
- 算法实现（Algorithm implementation）：有时简称为实现（implementation），是算法的具体实现。这主要以代码形式表示为一组函数。
- CAVS 是密码算法验证系统。这是一种工具，用于测试密码实现是否符合 FIPS 标准。
- CMVP 是密码模块验证程序。这个过程验证密码实现是否符合 FIPS 标准。
- EVP 是由 libcrypto 实现的一系列 API，使应用程序能够执行密码操作。EVP API 的实现使用 Core 和 Provider 组件。
  - 在OpenSSL中，EVP通常被解释为"high-level cryptographic functions"，但实际上，EVP并没有明确的全称。
  - 它是OpenSSL库中的一个模块名，主要提供了一系列高级加密函数的API，用于执行各种密码操作。这些操作包括但不限于对称加密、非对称加密、摘要算法等。
  - EVP API的设计目标是提供一种统一的接口，使得开发者可以在不关心底层具体加密算法实现的情况下，进行安全的密码操作。
  - 在OpenSSL中，EVP是Enveloped Data and Key Agreement或Enveloped Public Key的简写。-- 不够确切，来自中国csdn博主
  - EVP模块是一个密码学函数库，它提供了对称加密、非对称加密、哈希、消息认证码（MAC）、数字签名和密码学随机数生成等功能。
  - EVP模块为开发者提供了一个统一的接口，使得在不同的加密算法之间进行切换变得更加容易。
  - 通过EVP模块，开发者可以使用高级的密码学功能而无需直接调用具体的加密算法实现。
  - EVP封装了多种加密算法（如AES、DES）、非对称加密算法（如RSA、DSA、ECC）、哈希算法（如SHA-1、SHA-256）等，同时提供了数字签名和密钥派生等高级功能。
  - EVP系列的函数声明包含在“evp.h”中，这是一系列封装了OpenSSL加密库里面所有算法的函数。
  - 通过EVP系列的函数，可以很方便地实现加密、解密、签名和验证等操作，而无需关心底层的实现细节。
  - 需要注意的是，在使用EVP进行加密和解密操作时，需要遵循一定的流程，如初始化上下文、设置密钥和初始化向量、执行加密或解密操作等。
  - 最后，由于加密和安全性是复杂且敏感的领域，当在实际应用中使用EVP或任何其他加密库时，请确保你充分理解其工作原理，并遵循最佳的安全实践。
  - 如果需要处理敏感数据或需要高级别的安全性，请考虑咨询专业的安全顾问或团队。

- Core 是 libcrypto 中的一个组件，使应用程序能够访问 Provider 提供的算法实现。
- CSP 是关键安全参数（Critical Security Parameters）。这包括在未经授权的披露或修改的情况下可能损害模块安全性的任何信息（例如私钥、密码、PIN 码等）。
- 显式获取（Explicit Fetch）是一种查找算法实现的方法，应用程序通过显式调用来定位实现并提供搜索条件。
- FIPS 是联邦信息处理标准（Federal Information Processing Standards）。这是由美国政府定义的一组标准。特别是 FIPS 140-2 标准适用于密码软件。
  - FIPS 模块是经过 CMVP 验证符合 FIPS 标准的密码算法实现。在 OpenSSL 中，FIPS 模块以 Provider 的形式实现，并以可动态加载模块的形式提供。
- 隐式获取（Implicit Fetch）是一种查找算法实现的方法，应用程序不会显式调用来定位实现，因此会使用默认的搜索条件。
- 完整性检查（Integrity Check）是在加载 FIPS 模块时自动运行的测试。模块会对自身进行校验，并验证是否被恶意修改。
- KAS 是密钥协商方案（Key Agreement Scheme）。它是两个通信方协商共享密钥的方法。
- KAT 是已知答案测试（Known Answer Tests）。它是用于对 FIPS 模块进行健康检查的一组测试。
- 
- libcrypto 是 OpenSSL 实现的一个共享库，为应用程序提供各种与密码学相关的功能。
- libssl 是 OpenSSL 实现的一个共享库，为应用程序提供创建 SSL/TLS 连接的能力，可以作为客户端或服务器。
- 库上下文（Library Context）是一个不透明结构，保存库的“全局”数据。
- 操作（Operation）是对数据执行的一类函数，如计算摘要、加密、解密等。一个算法可以提供一个或多个操作。例如，RSA 提供非对称加密、非对称解密、签名、验证等。
- 参数（Parameters）是一组与实现无关的键值对，用于在 Core 和 Provider 之间传递对象数据。例如，它们可以用于传输私钥数据。
- POST 指的是 FIPS 模块的上电自检（也称为开机自检），在安装、上电（即每次为应用程序加载 FIPS 模块时）或按需运行。
  - 这些测试包括完整性检查和 KAT。如果 KAT 在安装时成功运行，则在上电时不需要再次运行，但始终执行完整性检查。
- 属性（Properties）用于 Provider 描述其算法实现的特性。它们还用于应用程序查询以查找特定实现。
- Provider 是提供一个或多个算法实现的单元。
- Provider 模块是以可动态加载模块形式的 Provider。

## 架构
### 架构应具备以下特性：
- 公共服务（Common Services）是应用程序和 Provider 共用的构建模块，例如 BIO、X509、SECMEM、ASN.1 等。
- Provider 实现密码算法和支持服务。一个算法可能由多个操作组成（例如 RSA 可能有“加密”、“解密”、“签名”、“验证”等）。同样，一个操作（例如“签名”）可以由多个算法实现，比如 RSA 和 ECDSA。Provider 包含了算法的密码原语实现。此版本将包括以下 Provider：
  - a. 默认 Provider（Default），包含当前非遗留（non-legacy）的 OpenSSL 密码算法；这将作为内置部分（即 libcrypto 的一部分）。
  - b. 遗留 Provider（Legacy），包含旧算法的实现（例如 DES、MDC2、MD2、Blowfish、CAST）。
  - c. FIPS Provider，实现 OpenSSL FIPS 密码模块 3.0；可以在运行时动态加载。
- Core 使应用程序（和其他 Provider）能够访问 Provider 提供的操作。Core 是定位操作的具体实现的机制。
- 协议实现，例如 TLS、DTLS。
  - 本文档中有许多关于“EVP API”的引用。这指的是“应用级别”的操作，例如公钥签名、生成摘要等。
  - 这些函数包括 EVP_DigestSign、EVP_Digest、EVP_MAC_init 等。EVP API 还封装了执行这些服务所使用的密码对象，
  - 例如 EVP_PKEY、EVP_CIPHER、EVP_MD、EVP_MAC 等等。
  - Provider 为后者集合实现了后端功能。这些对象的实例可以根据应用程序的需求隐式或显式地绑定到 Provider 上。
  - 下面的 Provider 设计部分将详细讨论。

### 架构具有以下特点：
- EVP 层是对 Provider 中实现的操作的薄封装，大多数调用会直接传递，几乎没有预处理或后处理过程。
- 将提供新的 EVP API，以影响 Core 如何选择（或查找）要在任何给定 EVP 调用中使用的操作的实现方式。
- 以与实现无关的方式在 libcrypto 和 Provider 之间传递信息。
- 将弃用遗留 API（例如不通过 EVP 层的低级密码 API）。存在针对非遗留算法的遗留 API（例如 AES 不是遗留算法，但 AES_encrypt 是遗留 API）。
- OpenSSL FIPS 密码模块将作为动态加载的 Provider 实现，它将是自包含的（即只能依赖于系统运行时库和核心提供的服务）。
