# Authentication Module

## Overview

The **Authentication Module** ensures the security and integrity of the classical communication channel in the Quantum Key Distribution (QKD) system. It incorporates advanced authentication mechanisms to verify transmitted and received data, leveraging lightweight hashing techniques to minimize resource usage while maintaining high security.

## Key Features

### High-Security Standards
- Implements the lightweight authentication method described in <light weight authentication in quantum key distillation>.
- Minimizes memory usage to accommodate the storage-intensive nature of the distillation process.

### Three-Step Authentication Process
1. **Polynomial Hashing**:
   - Uses an efficient Barrett Reduction algorithm for modulus calculations.
   - Employs an 8-bit accumulator and a 248-bit shift register for data processing.
2. **Toeplitz Hashing**:
   - Utilizes FPGA's Digital Signal Processor (DSP) units for matrix multiplication.
   - Incorporates modulus-2 operations with XOR gates for high-speed bitwise computations.
3. **OTP Hashing**:
   - Generates a secure hash tag using a simple XOR operation between Toeplitz hashing output and the OTP key.

### Pre-Shared Key Management
- Initializes the system with a pre-shared key for the first authentication.
- Dynamically updates the authentication key with the secret key after generation.
- Manages key storage efficiently using the AXI-Lite interface.

## Authentication Process

### Polynomial Hashing
- Calculates hashes using:

![圖片](https://github.com/user-attachments/assets/b5838985-b2b1-4ef3-8281-f7e412a272f3)

- Reduces computational complexity with the **Barrett Reduction Algorithm**, where:

![圖片](https://github.com/user-attachments/assets/ddead3e8-5f6a-46a9-afbe-12d92a30b5d7)
M = 2^{32} - 5

![圖片](https://github.com/user-attachments/assets/e50c1ceb-b45c-48e0-b72e-0a5da4908f4f)

![圖片](https://github.com/user-attachments/assets/6dc08e32-1960-42de-9199-765a16139b22)


### Toeplitz Hashing
- Leverages DSP units for matrix multiplication.
- Computes modulus-2 operations using XOR gates for efficient bitwise calculations.

### OTP Hashing
- Enhances security with an XOR operation:
  Hash Tag =(Toeplitz Output) ^ (OTP Key)

## Configuration Map
The memory layout for pre-shared and dynamically updated keys is outlined below:

| **Name**           | **Address**     | **Bits** | **Definition**                         |
|---------------------|-----------------|----------|-----------------------------------------|
| Polynomial key 1    | 0x0000_0000     | 64       | Bits 63 to 0 of the polynomial key      |
| Polynomial key 2    | 0x0000_0008     | 64       | Bits 127 to 64 of the polynomial key    |
| Polynomial key 3    | 0x0000_0010     | 58       | Bits 185 to 128 of the polynomial key   |
| Toeplitz key 1      | 0x0000_0018     | 64       | Bits 63 to 0 of the Toeplitz key        |
| Toeplitz key 2      | 0x0000_0020     | 64       | Bits 127 to 64 of the Toeplitz key      |
| Toeplitz key 3      | 0x0000_0028     | 64       | Bits 191 to 128 of the Toeplitz key     |
| Toeplitz key 4      | 0x0000_0030     | 39       | Bits 230 to 192 of the Toeplitz key     |
| OTP key             | 0x0000_0038     | 40       | Bits 39 to 0 of the OTP key             |

## Quantum Key Consumption
Quantum keys are utilized for both recycled key ($L_{rec}$) and OTP key ($L_{OTP}$). The table below highlights the key consumption for various configurations:

| **$\mu$, Mbits** | **$L_{rec}$, bits ($w=31$)** | **$L_{OTP}$, bits ($w=31$)** | **$L_{rec}$, bits ($w=63$)** | **$L_{OTP}$, bits ($w=63$)** |
|------------------|------------------------------|------------------------------|------------------------------|------------------------------|
| 1                | 229                          | 40                           | 166                          | 40                           |
| 4                | 291                          | 40                           | 166                          | 40                           |
| 16               | 291                          | 40                           | 166                          | 40                           |
| 64               | 354                          | 40                           | 293                          | 40                           |
| 256              | 417                          | 40                           | 293                          | 40                           |

## Architecture

### Block Diagram
The authentication process comprises three main components: polynomial hashing, Toeplitz hashing, and OTP hashing. Below is the system architecture:

![圖片](https://github.com/user-attachments/assets/c2208f1f-37f3-4811-ae0c-6abed7e21f5e)

### Toeplitz Hashing
Matrix multiplications are accelerated using FPGA's DSP units for efficient hash computation.

![圖片](https://github.com/user-attachments/assets/dba3aad6-ed22-40ea-afaf-ba38135b86b1)

### MAC Unit
Illustrates the multiplication and XOR operations employed in the authentication process.

![圖片](https://github.com/user-attachments/assets/d00bcb1a-2da0-486b-84f4-dff50bc56a8d)
