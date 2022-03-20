#ifndef BASE64CIRCLEIMAGEPROVIDER_H
#define BASE64CIRCLEIMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QBitmap>
#include <QPainter>

class Base64CircleImageProvider : public QQuickImageProvider
{
public:
    Base64CircleImageProvider()
               : QQuickImageProvider(QQuickImageProvider::Pixmap)
    {
    }

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override
    {
       int w = requestedSize.width() > 0 ? requestedSize.width() : size->width();
       int h = requestedSize.height() > 0 ? requestedSize.height() : size->height();

       QString data_string = id;
       const QByteArray data = QByteArray::fromBase64(data_string.replace("data:image/png;base64,", "").replace("data:image/jpg;base64,", "").toUtf8());
       QPixmap pixmap;
       pixmap.loadFromData(data);

       QBitmap map(pixmap.width(),pixmap.height());
       map.fill(Qt::color0);

       QPainter painter( &map );
       painter.setBrush(Qt::color1);
       painter.drawEllipse(3,3,pixmap.width()-6,pixmap.height()-6);
       painter.setRenderHint(QPainter::Antialiasing);

       pixmap.setMask(map);

       pixmap = pixmap.scaled(w,h,Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);

       return pixmap;
    }
};

#endif // BASE64CIRCLEIMAGEPROVIDER_H
