#ifndef UTILITY_H
#define UTILITY_H

#include <QObject>
#include <QBuffer>
#include <QDebug>
#include <QPainter>

class Utility : public QObject
{
    Q_OBJECT

public:
    explicit Utility (QObject* parent = 0) : QObject(parent) {}
    QString GetRandomString() const
    {
       const QString possibleCharacters("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");
       const int randomStringLength = 12; // assuming you want random strings of 12 characters

       QString randomString;
       for(int i=0; i<randomStringLength; ++i)
       {
           int index = qrand() % possibleCharacters.length();
           QChar nextChar = possibleCharacters.at(index);
           randomString.append(nextChar);
       }
       return randomString;
    }
    Q_INVOKABLE bool saveBase64(QString base64, QString name, QString type){
        auto proposedDest = QString("%1/%2").arg(QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)).arg(name + "." + type);

        auto dest = QFileDialog::getSaveFileName(
            nullptr,
            tr("Save Image"),
            proposedDest);

        if (!dest.isEmpty())
        {
            QImage image1;
            image1.loadFromData(QByteArray::fromBase64(base64.toUtf8()));
            image1.save(dest);
        }
        else{
            return false;
        }
        return true;
    }
    Q_INVOKABLE QString toBase64(QString url) {
        QImage image1(url.replace("file://", ""));
        QImage image2(image1.size(), QImage::Format_RGB32);
        image2.fill(QColor(Qt::white).rgb());
        QPainter painter(&image2);
        painter.drawImage(0, 0, image1);
        QBuffer buffer;
        buffer.open(QIODevice::WriteOnly);
        //if(image2.width() > 300)
            //image2 = image2.scaled(300, 300, Qt::KeepAspectRatio);
        image2.save(&buffer, "jpeg", 80);
        QString encoded = buffer.data().toBase64();
        int w = image2.width(), h = image2.height();
        int maxs = 550;
        if(w > maxs && w >= h){
            w=maxs;
            h=maxs/image2.width()*image2.height();
        }
        else if(h > maxs){
            h=maxs;
            w=maxs/image2.height()*image2.width();
        }
        encoded = "<a href=\"" + GetRandomString() + "\"><img width=\"" + QString::number(w) + "\" height=\"" + QString::number(h) + "\" src=\"data:image/jpg;base64," + encoded + "\" /></a>";
        return encoded;
    }

    Q_INVOKABLE QString toBase64_PNG(QString url, int w_, int h_) {
        QImage image1(url.replace("file://", ""));
        QImage image2(image1.size(), QImage::Format_RGB32);
        image2.fill(QColor(Qt::white).rgb());
        QPainter painter(&image2);
        painter.drawImage(0, 0, image1);
        painter.end();
        QBuffer buffer;
        buffer.open(QIODevice::WriteOnly);
        if(image2.width() > w_ || image2.height() > h_)
            image2 = image2.scaled(w_, h_, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        image2.save(&buffer, "png");
        QString encoded = buffer.data().toBase64();

        encoded = "data:image/png;base64," + encoded;
        return encoded;
    }

    Q_INVOKABLE bool checkFileExists(QString path) {
        return QFile::exists(path);
    }

    Q_INVOKABLE void startNewInstance(QString id) {
        QStringList a;
        a << id;
        QProcess::startDetached(qApp->arguments()[0], a);
    }
};

#endif // UTILITY_H
