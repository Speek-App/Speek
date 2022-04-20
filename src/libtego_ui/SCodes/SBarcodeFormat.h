#ifndef SBARCODEFORMAT_H
#define SBARCODEFORMAT_H

#include <qqml.h>
#include "BarcodeFormat.h"

namespace SCodes {
    Q_NAMESPACE
    QML_ELEMENT

    enum class SBarcodeFormat : int {
        None            = 0,
        Aztec           = (1 << 0),
        Codabar         = (1 << 1),
        Code39          = (1 << 2),
        Code93          = (1 << 3),
        Code128         = (1 << 4),
        DataBar         = (1 << 5),
        DataBarExpanded = (1 << 6),
        DataMatrix      = (1 << 7),
        EAN8            = (1 << 8),
        EAN13           = (1 << 9),
        ITF             = (1 << 10),
        MaxiCode        = (1 << 11),
        PDF417          = (1 << 12),
        QRCode          = (1 << 13),
        UPCA            = (1 << 14),
        UPCE            = (1 << 15),

        OneDCodes = Codabar | Code39 | Code93 | Code128 | EAN8 | EAN13 | ITF | DataBar | DataBarExpanded | UPCA | UPCE,
        TwoDCodes = Aztec | DataMatrix | MaxiCode | PDF417 | QRCode,
        Any       = OneDCodes | TwoDCodes,
        Basic     = Code39 | Code93 | Code128 | QRCode | DataMatrix,
    };

    Q_DECLARE_FLAGS(SBarcodeFormats, SBarcodeFormat)
    Q_DECLARE_OPERATORS_FOR_FLAGS(SBarcodeFormats)
    Q_FLAG_NS(SBarcodeFormats)

    ZXing::BarcodeFormat toZXingFormat(SBarcodeFormat format);
    ZXing::BarcodeFormats toZXingFormat(SBarcodeFormats formats);

    QString toString(SBarcodeFormat format);
    SBarcodeFormat fromString(const QString &formatName);
}

#endif // SBARCODEFORMAT_H
