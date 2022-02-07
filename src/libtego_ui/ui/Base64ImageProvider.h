#ifndef BASE64IMAGEPROVIDER_H
#define BASE64IMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QBitmap>
#include <QPainter>

class Base64ImageProvider : public QQuickImageProvider
{
public:
    Base64ImageProvider()
               : QQuickImageProvider(QQuickImageProvider::Pixmap)
    {
    }

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override
    {
       Q_UNUSED(size);Q_UNUSED(requestedSize);

       QString data_string = id;
       const QByteArray data = QByteArray::fromBase64(data_string.replace("data:image/png;base64,", "").toUtf8());
       QPixmap pixmap;
       pixmap.loadFromData(data);

       return pixmap;
    }
};

#endif // BASE64IMAGEPROVIDER_H
