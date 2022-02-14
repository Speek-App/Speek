#ifndef UTILITY_H
#define UTILITY_H

#include <QObject>
#include <QBuffer>
#include <QDebug>
#include <QPainter>
#include <QDir>
#include <QDesktopServices>

#include <quazip/quazip.h>
#include <quazip/quazipfile.h>


class Utility : public QObject
{
    Q_OBJECT

public:
    explicit Utility (QObject* parent = 0) : QObject(parent) {}
    QString GetRandomString() const
    {
       const QString possibleCharacters("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");
       const int randomStringLength = 12;

       QString randomString;
       for(int i=0; i<randomStringLength; ++i)
       {
           int index = QRandomGenerator::global()->generate() % possibleCharacters.length();
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
        #ifdef Q_OS_WIN
            QImage image1(url.replace("file:///", "").replace("/","\\\\"));
        #else
            QImage image1(url.replace("file://", ""));
        #endif
        QImage image2(image1.size(), QImage::Format_RGB32);
        image2.fill(QColor(Qt::white).rgb());
        QPainter painter(&image2);
        painter.drawImage(0, 0, image1);
        QBuffer buffer;
        buffer.open(QIODevice::WriteOnly);

        const int maxs_total = 900;
        if(image2.width() > maxs_total || image2.height() > maxs_total)
            image2 = image2.scaled(maxs_total, maxs_total, Qt::KeepAspectRatio);

        image2.save(&buffer, "jpeg", 70);
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
        #ifdef Q_OS_WIN
            QImage image1(url.replace("file:///", "").replace("/","\\\\"));
        #else
            QImage image1(url.replace("file://", ""));
        #endif
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

    Q_INVOKABLE QVariantList getIdentities() {
        QVariantList a;
        for (QString const& name: QDir(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation)).entryList(QDir::AllDirs | QDir::NoDotAndDotDot))
        {
            if(name != "tor" && name != "cache"){
                QVariantMap p;
                p.insert("name", name);

                QFile f(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/" + name + "/speek.json");
                if (!f.open(QFile::ReadOnly | QFile::Text)){
                    p.insert("contacts", "unknown");
                }
                else{
                    QTextStream in(&f);
                    QString c = QString::number(in.readAll().count("\"type\": \"allowed\""));
                    p.insert("contacts", c);
                    QFileInfo ff(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/" + name + "/speek.json");
                    p.insert("created", ff.birthTime().toString());
                }

                a.push_back(p);
            }
        }

        return a;
    }

    Q_INVOKABLE QString platformPath(QString url) {
        #ifdef Q_OS_WIN
            return url.replace("file:///", "file:/");
        #else
            return url;
        #endif
    }

    static void recurseAddDir(QDir d, QStringList & list) {

        QStringList qsl = d.entryList(QDir::NoDotAndDotDot | QDir::Dirs | QDir::Files);

        foreach (QString file, qsl) {

            QFileInfo finfo(QString("%1/%2").arg(d.path()).arg(file));

            if (finfo.isSymLink())
                return;

            if (finfo.isDir()) {

                QString dirname = finfo.fileName();
                QDir sd(finfo.filePath());

                recurseAddDir(sd, list);

            } else
                list << QDir::toNativeSeparators(finfo.filePath());
        }
    }

    static QTemporaryDir tempDir;

    static bool createZipFromMultipleFiles(QStringList sl, QString fileName){
        QuaZip zip(fileName);
        zip.setFileNameCodec("IBM866");

        if (!zip.open(QuaZip::mdCreate)) {
            return false;
        }

        QFile inFile;

        QFileInfoList files;

        foreach (QString fn, sl)
            #ifdef Q_OS_WIN
                files << QFileInfo(fn.replace("file:///", "").replace("/","\\\\"));
            #else
                files << QFileInfo(fn.replace("file://", ""));
            #endif

        QuaZipFile outFile(&zip);

        char c;
        foreach(QFileInfo fileInfo, files) {

            if (!fileInfo.isFile())
                continue;

            QString fileNameWithRelativePath = fileInfo.fileName();

            inFile.setFileName(fileInfo.filePath());

            if (!inFile.open(QIODevice::ReadOnly)) {
                return false;
            }

            if (!outFile.open(QIODevice::WriteOnly, QuaZipNewInfo(fileNameWithRelativePath, fileInfo.filePath()))) {
                return false;
            }

            while (inFile.getChar(&c) && outFile.putChar(c));

            if (outFile.getZipError() != UNZ_OK) {
                return false;
            }

            outFile.close();

            if (outFile.getZipError() != UNZ_OK) {
                return false;
            }

            inFile.close();
        }

        zip.close();

        if (zip.getZipError() != 0) {
            return false;
        }

        return true;
    }

    static bool createZipFromFolder(QDir dir, QString fileName){
        QuaZip zip(fileName);
        zip.setFileNameCodec("IBM866");

        if (!zip.open(QuaZip::mdCreate)) {
            return false;
        }

        if (!dir.exists()) {
            return false;
        }

        QFile inFile;

        QStringList sl;
        recurseAddDir(dir, sl);

        QFileInfoList files;
        foreach (QString fn, sl) files << QFileInfo(fn);

        QuaZipFile outFile(&zip);

        char c;
        foreach(QFileInfo fileInfo, files) {

            if (!fileInfo.isFile())
                continue;

            QString fileNameWithRelativePath = fileInfo.filePath().remove(0, dir.absolutePath().length() + 1);

            inFile.setFileName(fileInfo.filePath());

            if (!inFile.open(QIODevice::ReadOnly)) {
                return false;
            }

            if (!outFile.open(QIODevice::WriteOnly, QuaZipNewInfo(fileNameWithRelativePath, fileInfo.filePath()))) {
                return false;
            }

            while (inFile.getChar(&c) && outFile.putChar(c));

            if (outFile.getZipError() != UNZ_OK) {
                return false;
            }

            outFile.close();

            if (outFile.getZipError() != UNZ_OK) {
                return false;
            }

            inFile.close();
        }

        zip.close();

        if (zip.getZipError() != 0) {
            return false;
        }

        return true;
    }

    Q_INVOKABLE bool exportBackup(QString name) {
        QString fileName = QFileDialog::getSaveFileName(nullptr, tr("Save File"), name + "_Speek_Backup.zip", ".zip");
        if (fileName.isEmpty()) {
            return false;
        }
        QDir dir(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation));

        return createZipFromFolder(dir, fileName);
    }

    static qint64 dirSize(QString dirPath) {
        qint64 size = 0;
        QDir dir(dirPath);

        QDir::Filters fileFilters = QDir::Files|QDir::System|QDir::Hidden;
        for(QString filePath : dir.entryList(fileFilters)) {
            QFileInfo fi(dir, filePath);
            size+= fi.size();
        }

        QDir::Filters dirFilters = QDir::Dirs|QDir::NoDotAndDotDot|QDir::System|QDir::Hidden;
        for(QString childDirPath : dir.entryList(dirFilters))
            size+= dirSize(dirPath + QDir::separator() + childDirPath);
        return size;
    }

    static bool dirBiggerAs(QString dirPath, qint64 maxSize, qint64 &size_) {
        qint64 size = 0;
        QDir dir(dirPath);

        QDir::Filters fileFilters = QDir::Files|QDir::System|QDir::Hidden;
        for(QString filePath : dir.entryList(fileFilters)) {
            QFileInfo fi(dir, filePath);
            size += fi.size();
            if(size > maxSize)
                return true;
        }

        QDir::Filters dirFilters = QDir::Dirs|QDir::NoDotAndDotDot|QDir::System|QDir::Hidden;
        for(QString childDirPath : dir.entryList(dirFilters)){
            size += dirSize(dirPath + QDir::separator() + childDirPath);
            if(size > maxSize)
                return true;
        }
        size_ = size;
        return false;
    }

    Q_INVOKABLE QVariantMap makeTempZipFromFolder(QString dir_) {
        QVariantMap values;

        #ifdef Q_OS_WIN
            dir_ = dir_.replace("file:///", "").replace("/","\\\\");
        #else
            dir_ = dir_.replace("file://", "");
        #endif

        //up to 100MB only
        qint64 size = 0;
        QDir dir(dir_);
        if(dirBiggerAs(dir.path(), 104857600, size)){
            values.insert("error", tr("All files combined too big (max 100MB)"));
            return values;
        }

        QString fileName = tempDir.path() + QDir::separator() + dir.dirName() + ".zip";

        values.insert("filePath", fileName);
        values.insert("fileName", dir.dirName() + ".zip");
        QLocale locale = QLocale::system();
        QString valueText = locale.formattedDataSize(size);
        values.insert("size", valueText);

        if (fileName.isEmpty() || dir.dirName().isEmpty()) {
            values.insert("error", tr("Invalid folder path"));
            return values;
        }

        if(createZipFromFolder(dir, fileName)){
            values.insert("error", "");
            return values;
        }
        else{
            values.insert("error", tr("Unable to create zip archive"));
            return values;
        }
    }

    Q_INVOKABLE QVariantMap makeTempZipFromMultipleFiles(QStringList files) {
        QVariantMap values;
        if(files.empty()){
            values.insert("error", tr("No files selected"));
            return values;
        }

        QString name = QFileInfo(files[0]).fileName().replace(".","_");
        if(files.size() > 1)
            name += "_and_other_files";

        QString fileName = tempDir.path() + QDir::separator() + name + ".zip";

        values.insert("filePath", fileName);
        values.insert("fileName", name + ".zip");
        values.insert("size", "0");

        if (fileName.isEmpty() || name.isEmpty()) {
            values.insert("error", tr("Invalid folder path"));
            return values;
        }

        if(createZipFromMultipleFiles(files, fileName)){
            values.insert("error", "");
            return values;
        }
        else{
            values.insert("error", tr("Unable to create zip archive"));
            return values;
        }
    }

    Q_INVOKABLE void openWithDefaultApplication(QString file) {
        QDesktopServices::openUrl(QUrl::fromLocalFile(file));
    }
};

#endif // UTILITY_H
