#include "SBarcodeDecoder.h"

#include <QDebug>
#include <QImage>
#include <QtMultimedia/qvideoframe.h>
#include <QOpenGLContext>
#include <QOpenGLFunctions>
#include <iostream>

#include <ReadBarcode.h>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#include "qvideoframeconversionhelper_p.h"

namespace ZXing {
namespace Qt {

using ZXing::DecodeHints;
using ZXing::BarcodeFormat;
using ZXing::BarcodeFormats;
using ZXing::Binarizer;

template <typename T, typename _ = decltype(ToString(T()))>
QDebug operator<<(QDebug dbg, const T& v)
{
    return dbg.noquote() << QString::fromStdString(ToString(v));
}

class Result : private ZXing::Result
{
public:
    explicit Result(ZXing::Result&& r) : ZXing::Result(std::move(r)) {}

    using ZXing::Result::format;
    using ZXing::Result::isValid;
    using ZXing::Result::status;

    inline QString text() const { return QString::fromWCharArray(ZXing::Result::text().c_str()); }
};

Result ReadBarcode(const QImage& img, const DecodeHints& hints = {})
{
    auto ImgFmtFromQImg = [](const QImage& img) {
        switch (img.format()) {
        case QImage::Format_ARGB32:
        case QImage::Format_RGB32:
#if Q_BYTE_ORDER == Q_LITTLE_ENDIAN
            return ImageFormat::BGRX;
#else
            return ImageFormat::XRGB;
#endif
        case QImage::Format_RGB888: return ImageFormat::RGB;
        case QImage::Format_RGBX8888:
        case QImage::Format_RGBA8888: return ImageFormat::RGBX;
        case QImage::Format_Grayscale8: return ImageFormat::Lum;
        default: return ImageFormat::None;
        }
    };

    auto exec = [&](const QImage& img) {
        return Result(ZXing::ReadBarcode({img.bits(), img.width(), img.height(), ImgFmtFromQImg(img)}, hints));
    };

    return ImgFmtFromQImg(img) == ImageFormat::None ? exec(img.convertToFormat(QImage::Format_RGBX8888)) : exec(img);
}

} // Qt namespace
} // ZXing namespace

using namespace ZXing::Qt;

std::ostream& operator<<(std::ostream& os, const std::vector<ZXing::ResultPoint>& points) {
    for (const auto& p : points)
        os << int(p.x() + .5f) << "x" << int(p.y() + .5f) << " ";
    return os;
}

SBarcodeDecoder::SBarcodeDecoder(QObject *parent) : QObject(parent)
{

}

void SBarcodeDecoder::clean()
{
    _captured = "";
}

QString SBarcodeDecoder::captured() const
{
    return _captured;
}

void SBarcodeDecoder::setCaptured(const QString &captured)
{
    if (_captured == captured) {
        return;
    }

    _captured = captured;
    emit capturedChanged(_captured);
}

void SBarcodeDecoder::setIsDecoding(bool isDecoding)
{
    if (_isDecoding == isDecoding) {
        return;
    }

    _isDecoding = isDecoding;
    emit isDecodingChanged(_isDecoding);
}

bool SBarcodeDecoder::isDecoding() const
{
    return _isDecoding;
}

void SBarcodeDecoder::process(const QImage capturedImage, ZXing::BarcodeFormats formats)
{
    setIsDecoding(true);

    const auto hints = DecodeHints()
            .setFormats(formats)
            .setTryHarder(true)
            .setTryRotate(true)
            .setIsPure(false)
            .setBinarizer(Binarizer::LocalAverage);

    const auto result = ReadBarcode(capturedImage, hints);

    if (result.isValid()) {
       setCaptured(result.text());
    }

    setIsDecoding(false);
}

QImage SBarcodeDecoder::videoFrameToImage(QVideoFrame &videoFrame, const QRect &captureRect)
{
    if (videoFrame.handleType() == QAbstractVideoBuffer::NoHandle) {

#if (QT_VERSION >= QT_VERSION_CHECK(5, 15, 0))
        QImage image = videoFrame.image();
#else

        videoFrame.map(QAbstractVideoBuffer::ReadOnly);
        QImage image = imageFromVideoFrame(videoFrame);
        videoFrame.unmap();

#endif

        if (image.isNull()) {
            return QImage();
        }

        if ( image.format() != QImage::Format_ARGB32) {
            image = image.convertToFormat(QImage::Format_ARGB32);
        }

        return image.copy(captureRect);
    }

    if (videoFrame.handleType() == QAbstractVideoBuffer::GLTextureHandle) {
        QImage image(videoFrame.width(), videoFrame.height(), QImage::Format_ARGB32);
        GLuint textureId = static_cast<GLuint>(videoFrame.handle().toInt());
        QOpenGLContext* ctx = QOpenGLContext::currentContext();
        QOpenGLFunctions* f = ctx->functions();
        GLuint fbo;
        f->glGenFramebuffers( 1, &fbo);
        GLint prevFbo;
        f->glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prevFbo);
        f->glBindFramebuffer(GL_FRAMEBUFFER, fbo);
        f->glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureId, 0);
        f->glReadPixels(0, 0,  videoFrame.width(),  videoFrame.height(), GL_RGBA, GL_UNSIGNED_BYTE, image.bits());
        f->glBindFramebuffer( GL_FRAMEBUFFER, static_cast<GLuint>( prevFbo ) );
        return image.rgbSwapped().copy(captureRect);
    }

    return QImage();
}

QImage SBarcodeDecoder::imageFromVideoFrame(const QVideoFrame &videoFrame)
{
    uchar* ARGB32Bits = new uchar[(videoFrame.width() * videoFrame.height()) * 4];
    QImage::Format imageFormat = videoFrame.imageFormatFromPixelFormat(videoFrame.pixelFormat());
    if(imageFormat == QImage::Format_Invalid) {
        switch(videoFrame.pixelFormat()) {
            case QVideoFrame::Format_YUYV: qt_convert_YUYV_to_ARGB32(videoFrame, ARGB32Bits); break;
            case QVideoFrame::Format_NV12: qt_convert_NV12_to_ARGB32(videoFrame, ARGB32Bits); break;
            case QVideoFrame::Format_YUV420P: qt_convert_YUV420P_to_ARGB32(videoFrame, ARGB32Bits); break;
            case QVideoFrame::Format_YV12: qt_convert_YV12_to_ARGB32(videoFrame, ARGB32Bits); break;
            case QVideoFrame::Format_AYUV444: qt_convert_AYUV444_to_ARGB32(videoFrame, ARGB32Bits); break;
            case QVideoFrame::Format_YUV444: qt_convert_YUV444_to_ARGB32(videoFrame, ARGB32Bits); break;
            case QVideoFrame::Format_UYVY: qt_convert_UYVY_to_ARGB32(videoFrame, ARGB32Bits); break;
            case QVideoFrame::Format_NV21: qt_convert_NV21_to_ARGB32(videoFrame, ARGB32Bits); break;
            case QVideoFrame::Format_BGRA32: qt_convert_BGRA32_to_ARGB32(videoFrame, ARGB32Bits); break;
            case QVideoFrame::Format_BGR24: qt_convert_BGR24_to_ARGB32(videoFrame, ARGB32Bits); break;
            case QVideoFrame::Format_BGR565: qt_convert_BGR565_to_ARGB32(videoFrame, ARGB32Bits); break;
            case QVideoFrame::Format_BGR555: qt_convert_BGR555_to_ARGB32(videoFrame, ARGB32Bits); break;
            default: break;
        }

        return QImage(ARGB32Bits,
                      videoFrame.width(),
                      videoFrame.height(),
                      QImage::Format_ARGB32);
    }

    return QImage(videoFrame.bits(),
                  videoFrame.width(),
                  videoFrame.height(),
                  imageFormat);
}
