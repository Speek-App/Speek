#include "SBarcodeGenerator.h"
#include <QStandardPaths>
#ifdef Q_OS_ANDROID
#include <QtAndroid>
#endif
#include "MultiFormatWriter.h"
#include "TextUtfEncoding.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

SBarcodeGenerator::SBarcodeGenerator(QQuickItem *parent)
    : QQuickItem(parent)
{

}

bool SBarcodeGenerator::generate(const QString &inputString)
{
    try {
        if (inputString.isEmpty()) {
            return false;
        } else {
            ZXing::MultiFormatWriter writer = ZXing::MultiFormatWriter(SCodes::toZXingFormat(m_format)).setMargin(_margin).setEccLevel(_eccLevel);

            _bitmap = ZXing::ToMatrix<uint8_t>(writer.encode(ZXing::TextUtfEncoding::FromUtf8(inputString.toStdString()), _width, _height));

            _filePath = QDir::tempPath() + "/" + _fileName + "." + _extension;

            if (_extension == "png") {
                stbi_write_png(_filePath.toStdString().c_str(), _bitmap.width(), _bitmap.height(), 1, _bitmap.data(), 0);
            } else if (_extension == "jpg" || _extension == "jpeg") {
                stbi_write_jpg(_filePath.toStdString().c_str(), _bitmap.width(), _bitmap.height(), 1, _bitmap.data(), 0);
            }

            emit generationFinished();

            return true;
        }
    } catch (const std::exception &e) {
        emit generationFinished(e.what());
    } catch (...) {
        emit generationFinished("Unsupported exception thrown");
    }

    return false;
}



bool SBarcodeGenerator::saveImage()
{
    if (_filePath.isEmpty()) {
        return false;
    }

#ifdef Q_OS_ANDROID
    if (QtAndroid::checkPermission(QString("android.permission.WRITE_EXTERNAL_STORAGE")) == QtAndroid::PermissionResult::Denied){
        QtAndroid::PermissionResultMap resultHash = QtAndroid::requestPermissionsSync(QStringList({"android.permission.WRITE_EXTERNAL_STORAGE"}));
        if (resultHash["android.permission.WRITE_EXTERNAL_STORAGE"] == QtAndroid::PermissionResult::Denied) {
            return false;
        }
    }
#endif

    QString docFolder = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/" + _fileName + "." + _extension;

    QFile::copy(_filePath, docFolder);

    return true;
}

SCodes::SBarcodeFormat SBarcodeGenerator::format() const
{
    return m_format;
}

void SBarcodeGenerator::setFormat(SCodes::SBarcodeFormat format)
{
    if (m_format != format) {
        switch (format) {
        case SCodes::SBarcodeFormat::None:
            qWarning() << "You need to set a specific format";
            return;
        case SCodes::SBarcodeFormat::Any:
        case SCodes::SBarcodeFormat::OneDCodes:
        case SCodes::SBarcodeFormat::TwoDCodes:
            qWarning() << "Multiple formats can't be used to generate a barcode";
            return;
        default:
            m_format = format;
            emit formatChanged(m_format);
        }
    }
}

void SBarcodeGenerator::setFormat(const QString &formatName)
{
    setFormat(SCodes::fromString(formatName));
}
