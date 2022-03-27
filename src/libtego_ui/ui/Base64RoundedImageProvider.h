#ifndef BASE64ROUNDEDIMAGEPROVIDER_H
#define BASE64ROUNDEDIMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QBitmap>
#include <QPainter>

class Base64RoundedImageProvider : public QQuickImageProvider
{
public:
    Base64RoundedImageProvider()
               : QQuickImageProvider(QQuickImageProvider::Pixmap)
    {
    }

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override
    {
       //int w = requestedSize.width() > 0 ? requestedSize.width() : size->width();
       //int h = requestedSize.height() > 0 ? requestedSize.height() : size->height();

       QString data_string = id;
       const QByteArray data = QByteArray::fromBase64(data_string.replace("data:image/png;base64,", "").replace("data:image/jpg;base64,", "").toUtf8());
       QPixmap pixmap;
       pixmap.loadFromData(data);

       QBitmap map(pixmap.width(),pixmap.height());
       map.fill(Qt::color0);

       QPainter painter( &map );
       painter.setBrush(Qt::color1);
       int bb = pixmap.width() > pixmap.height() ? pixmap.width() : pixmap.height();
       painter.drawRoundedRect(0,0,pixmap.width(),pixmap.height(), bb*22/1000, bb*22/1000);
       painter.setRenderHint(QPainter::Antialiasing);

       pixmap.setMask(map);

       pixmap = pixmap.scaled(pixmap.width(),pixmap.height(),Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);

       return pixmap;
    }
};

#endif // BASE64ROUNDEDIMAGEPROVIDER_H
