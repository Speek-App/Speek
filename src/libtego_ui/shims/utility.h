#ifndef UTILITY_H
#define UTILITY_H

#include <QObject>
#include <QBuffer>
#include <QDebug>
#include <QPainter>
#include <QDir>
#include <QDesktopServices>
#include <QtConcurrent>

#ifndef _WIN32
#include <quazip/quazip.h>
#include <quazip/quazipfile.h>
#endif

#ifdef ANDROID
#include <QAndroidJniObject>
#include <QAndroidJniEnvironment>
#include <QtAndroid>
#endif

class Utility : public QObject
{
    Q_OBJECT

public:
    explicit Utility (QObject* parent = 0) : QObject(parent) {}
    static QString GetRandomString(int randomStringLength = 12)
    {
       const QString possibleCharacters("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");

       QString randomString;
       for(int i=0; i<randomStringLength; ++i)
       {
           int index = QRandomGenerator::global()->generate() % possibleCharacters.length();
           QChar nextChar = possibleCharacters.at(index);
           randomString.append(nextChar);
       }
       return randomString;
    }

#ifdef ANDROID
    Q_INVOKABLE static bool requestPermissionAndroid(QString permission)
    {
        auto result = QtAndroid::checkPermission(permission);

        if (result == QtAndroid::PermissionResult::Denied) {
            QtAndroid::PermissionResultMap resultHash = QtAndroid::requestPermissionsSync(QStringList({permission}));

            if (resultHash[permission] == QtAndroid::PermissionResult::Denied)
                return false;
        }
        return true;
    }
    static void android_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS(){
        QAndroidJniEnvironment env;
        QAndroidJniObject activity = QAndroidJniObject::callStaticObjectMethod("org/qtproject/qt5/android/QtNative", "activity", "()Landroid/app/Activity;");
        if ( activity.isValid() )
        {
            QAndroidJniObject intent("android/content/Intent","()V");
            if ( intent.isValid() )
            {
                QAndroidJniObject param1 = QAndroidJniObject::fromString("android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS");
                if ( param1.isValid() )
                {
                    QAndroidJniObject serviceName = QAndroidJniObject::getStaticObjectField<jstring>("android/content/Context","POWER_SERVICE");
                    if ( serviceName.isValid() )
                    {
                        QAndroidJniObject powerMgr = activity.callObjectMethod("getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;",serviceName.object<jobject>());
                        if ( powerMgr.isValid() )
                        {
                            QAndroidJniObject packageManager = activity.callObjectMethod("getPackageManager", "()Landroid/content/pm/PackageManager;");
                            if( packageManager.isValid() ){
                                QAndroidJniObject packageName = activity.callObjectMethod("getPackageName", "()Ljava/lang/String;");
                                if( packageName.isValid() ){
                                    qDebug()<<"Package Name: "<<packageName.toString();

                                    jboolean isIgnoringBatteryOptimizations = powerMgr.callMethod<jboolean>("isIgnoringBatteryOptimizations","(Ljava/lang/String;)Z",packageName.object<jstring>());
                                    qDebug()<<isIgnoringBatteryOptimizations;
                                    if( isIgnoringBatteryOptimizations == 0 ){
                                        qDebug()<<"isIgnoringBatteryOptimizations: False";
                                        intent.callObjectMethod("setAction","(Ljava/lang/String;)Landroid/content/Intent;",param1.object<jobject>());
                                        QAndroidJniObject PkgName = QAndroidJniObject::fromString("package:" + packageName.toString());
                                        QAndroidJniObject uri = QAndroidJniObject::callStaticObjectMethod("android/net/Uri","parse","(Ljava/lang/String;)Landroid/net/Uri;", PkgName.object<jstring>());
                                        intent.callObjectMethod("setData","(Landroid/net/Uri;)Landroid/content/Intent;",uri.object<jobject>());
                                        activity.callMethod<void>("startActivity","(Landroid/content/Intent;)V",intent.object<jobject>());
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if (env->ExceptionCheck()) {
            qWarning()<<"android_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS exception";
            env->ExceptionClear();
        }
    }

    Q_INVOKABLE bool minimizeAndroid(){
        QAndroidJniObject action_main = QAndroidJniObject::fromString("android.intent.action.MAIN");
        if ( action_main.isValid() )
        {
            QAndroidJniObject intent("android/content/Intent","(Ljava/lang/String;)V", action_main.object<jobject>());
            if ( intent.isValid() )
            {
                QAndroidJniObject activity = QAndroidJniObject::callStaticObjectMethod("org/qtproject/qt5/android/QtNative", "activity", "()Landroid/app/Activity;");
                if ( activity.isValid() )
                {
                    QAndroidJniObject param1 = QAndroidJniObject::fromString("android.intent.category.HOME");
                    if ( param1.isValid() )
                    {
                        intent.callObjectMethod("addCategory","(Ljava/lang/String;)Landroid/content/Intent;",param1.object<jobject>());
                        activity.callMethod<void>("startActivity","(Landroid/content/Intent;)V",intent.object<jobject>());
                        return true;
                    }
                }
            }
        }
        return false;
        /*Intent i = new Intent(Intent.ACTION_MAIN);
         i.addCategory(Intent.CATEGORY_HOME);
         startActivity(i);*/
    }
#endif

    Q_INVOKABLE bool saveBase64(QString base64, QString name, QString type){
        auto proposedDest = QString("%1/%2").arg(QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)).arg(name + "." + type);
        #ifndef ANDROID
            auto dest = QFileDialog::getSaveFileName(
                nullptr,
                tr("Save Image"),
                proposedDest);
        #else
            auto dest = QFileDialog::getSaveFileName(
                nullptr,
                name + "." + type,
                proposedDest);
        #endif

        if (!dest.isEmpty())
        {
            QImage image1;
            if(image1.loadFromData(QByteArray::fromBase64(base64.toUtf8()))){
                if(!image1.save(dest, type.toUtf8())){
                    qWarning()<<"saveBase64: Can not save image";
                    return false;
                }
            }
            else{
                return false;
            }
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
        int maxs = 450;
        if(w > maxs && w >= h){
            w=maxs;
            h=maxs*image2.height()/image2.width();
        }
        else if(h > maxs){
            h=maxs;
            w=maxs*image2.width()/image2.height();
        }
        encoded = "<html><head><meta name=\"qrichtext\"></head><body><img name=\"%Name%\" width=\"" + QString::number(w) + "\" height=\"" + QString::number(h) + "\" src=\"data:image/jpg;base64," + encoded + "\" /></body></html>";
        return encoded;
    }

    Q_INVOKABLE QString toBase64_JPG(QString url, int w_, int h_, int quality = 65) {
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

        image2 = image2.scaled(w_, h_, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
        image2.save(&buffer, "jpg", quality);
        QString encoded = buffer.data().toBase64();

        encoded = "data:image/jpg;base64," + encoded;
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

    Q_INVOKABLE void startGroup(QString id, QString groupName = "", QString contactRequestMessage = "", QStringList initialUsers = QStringList()) {
        #ifdef Q_OS_WIN
            QString filename(QStringLiteral("/speek-group.exe"));
        #else
            QString filename(QStringLiteral("/speek-group"));
        #endif

        QString path = qApp->applicationDirPath();
        if (QFile::exists(path + filename))
            path = path + filename;

        QStringList a;
        a << id;

        if(groupName != ""){
            a << groupName;
            if(contactRequestMessage != ""){
                a << contactRequestMessage;
                if(!initialUsers.empty()){
                    for(int i = 0; i<initialUsers.length(); i++){
                        a << initialUsers[i];
                    }
                }
            }
        }

        QProcess::startDetached(path, a);
    }

    Q_INVOKABLE QVariantList getIdentities(QString l = "") {
        QVariantList a;
        QString search_path;
        if(l == "")
            search_path = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
        else{
            search_path = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
            #if defined(Q_OS_MAC)
                search_path += "/speek-groups";
            #else
                QString appname("speek");
                search_path.replace(search_path.lastIndexOf(appname), appname.size(), l);
            #endif
        }

        for (QString const& name: QDir(search_path).entryList(QDir::AllDirs | QDir::NoDotAndDotDot))
        {
            if(name != "tor" && name != "cache" && name != "speek-groups"){
                QVariantMap p;
                p.insert("name", name);

                QFile f(search_path + "/" + name + "/speek.json");
                if (!f.open(QFile::ReadOnly | QFile::Text)){
                    p.insert("contacts", "unknown");
                }
                else{
                    QTextStream in(&f);
                    QString c = QString::number(in.readAll().count("\"type\": \"allowed\""));
                    p.insert("contacts", c);
                    QFileInfo ff(search_path + "/" + name + "/speek.json");
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
        #ifndef _WIN32
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
        #else
        QString filename(QStringLiteral("/7z/7z.exe"));
        QString path = qApp->applicationDirPath();

        if (QFile::exists(path + filename))
            path = path + filename;
        else
            return false;

        QStringList arguments;
        arguments << "a" << "-tzip" << fileName;
        foreach (QString fn, sl)
            arguments << fn.replace("file:///", "").replace("/","\\\\");

        QProcess process;
        process.start(path, arguments);
        process.waitForFinished();
        process.close();
        #endif
        return true;
    }

    static bool createZipFromFolder(QDir dir, QString fileName){
#ifndef _WIN32
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
        #else
        QString filename(QStringLiteral("/7z/7z.exe"));
        QString path = qApp->applicationDirPath();

        if (QFile::exists(path + filename))
            path = path + filename;
        else
            return false;

        QStringList arguments;
        arguments << "a" << "-tzip" << fileName << dir.path();

        QProcess process;
        process.start(path, arguments);
        process.waitForFinished();
        process.close();
        #endif
        return true;
    }

    static bool extractZip(const QString & filePath, const QString & extDirPath, const QString & singleFileName = QString("")) {
        #ifndef _WIN32
        QuaZip zip(filePath);

        if (!zip.open(QuaZip::mdUnzip)) {
            qWarning("testRead(): zip.open(): %d", zip.getZipError());
            return false;
        }

        zip.setFileNameCodec("IBM866");

        QuaZipFileInfo info;

        QuaZipFile file(&zip);

        QFile out;
        QString name;
        char c;
        for (bool more = zip.goToFirstFile(); more; more = zip.goToNextFile()) {

            if (!zip.getCurrentFileInfo(&info)) {
                qWarning("testRead(): getCurrentFileInfo(): %d\n", zip.getZipError());
                return false;
            }

            if (!singleFileName.isEmpty())
                if (!info.name.contains(singleFileName))
                    continue;

            if (!file.open(QIODevice::ReadOnly)) {
                qWarning("testRead(): file.open(): %d", file.getZipError());
                return false;
            }

            name = QString("%1/%2").arg(extDirPath).arg(file.getActualFileName());

            if (file.getZipError() != UNZ_OK) {
                qWarning("testRead(): file.getFileName(): %d", file.getZipError());
                return false;
            }

            out.setFileName(name);

            out.open(QIODevice::WriteOnly);
            while (file.getChar(&c)) out.putChar(c);

            out.close();

            if (file.getZipError() != UNZ_OK) {
                qWarning("testRead(): file.getFileName(): %d", file.getZipError());
                return false;
            }

            if (!file.atEnd()) {
                qWarning("testRead(): read all but not EOF");
                return false;
            }

            file.close();

            if (file.getZipError() != UNZ_OK) {
                qWarning("testRead(): file.close(): %d", file.getZipError());
                return false;
            }
        }

        zip.close();

        if (zip.getZipError() != UNZ_OK) {
            qWarning("testRead(): zip.close(): %d", zip.getZipError());
            return false;
        }

        #else

        #endif

        return true;
    }

    Q_INVOKABLE static bool restoreBackup() {
        QMessageBox::StandardButton btn = QMessageBox::question(0,
            tr("Delete current Indentity"),
            tr("Are sure you want to permanently delete your current identity in order to restore a backup?"));
        if(btn != QMessageBox::Yes)
            return false;

        QString backupPath = QFileDialog::getOpenFileName(nullptr, tr("Select Backup File"), QStandardPaths::writableLocation(QStandardPaths::DownloadLocation), tr("Zip files (*.zip)"));
        if (backupPath.isEmpty()) {
            return false;
        }

        //delete current config
        QDir dir(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation));
        dir.setNameFilters(QStringList() << "*.*");
        dir.setFilter(QDir::Files);
        foreach(QString dirFile, dir.entryList())
        {
            dir.remove(dirFile);
        }

        bool ret = extractZip(backupPath, QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation));

        if(ret){
            QMessageBox::StandardButton closeNow = QMessageBox::question(0, tr("Restart Required"), tr("A restart is required to load the restored identity. Should Speek close now?"));
            if(closeNow == QMessageBox::Yes)
                qApp->exit();
        }

        return ret;
    }

    Q_INVOKABLE static bool exportBackup(QString name) {
        #ifndef ANDROID
            QString fileName = QFileDialog::getSaveFileName(nullptr, tr("Save File"), name + "_Speek_Backup.zip", ".zip");
        #else
            QString fileName = QFileDialog::getSaveFileName(nullptr, name + "_Speek_Backup.zip", name + "_Speek_Backup.zip", ".zip");
        #endif

        if (fileName.isEmpty()) {
            return false;
        }
        QDir dir(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation));

        return createZipFromFolder(dir, fileName);
    }

    Q_INVOKABLE void exportBackupCallback(QString name, const QJSValue &callback) const
    {
        auto *watcher = new QFutureWatcher<bool>();
        QObject::connect(watcher, &QFutureWatcher<bool>::finished,
                         this, [this,watcher,callback]() {
            bool res = watcher->result();
            QJSValue callbackCopy(callback);
            QJSEngine *engine = qjsEngine(this);
            callbackCopy.call(QJSValueList { engine->toScriptValue(res) });
            watcher->deleteLater();
        });
        watcher->setFuture(QtConcurrent::run(&Utility::exportBackup, name));
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
        #elif ANDROID

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

    Q_INVOKABLE void openUserDataLocation() {
        QDir dir(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation));
        openWithDefaultApplication(dir.path());
    }

    Q_INVOKABLE bool createNewTheme(QString name) {
        QString fileName = QFileDialog::getSaveFileName(nullptr, tr("Save File"), "my_speek_theme", "");
        if (fileName.isEmpty()) {
            return false;
        }

        QString data;

        QFile file(":/themes/"+name);
        if(!file.open(QIODevice::ReadOnly))
            return false;
        else
            data = file.readAll();

        file.close();

        QFile file2(fileName);
        if (file2.open(QIODevice::ReadWrite)) {
            QTextStream stream(&file2);
            stream << data;
        }
        else{
            return false;
        }

        file2.close();

        return true;
    }

    Q_INVOKABLE void themeChanged() {
        QMessageBox::StandardButton closeNow = QMessageBox::question(0, tr("Restart Required"), tr("A restart is required to reload the theme. Should Speek close now?"));
        if(closeNow == QMessageBox::Yes)
            qApp->exit();
    }

    Q_INVOKABLE void fontSizeChanged() {
        QMessageBox::StandardButton closeNow = QMessageBox::question(0, tr("Restart Required"), tr("A restart is required to apply the font size change. Should Speek close now?"));
        if(closeNow == QMessageBox::Yes)
            qApp->exit();
    }

    Q_INVOKABLE static QString toHash(QString str){
        return QString(QCryptographicHash::hash((str.toUtf8()),QCryptographicHash::Md5).toHex());
    }

    // Open the given path with an appropriate application
     Q_INVOKABLE static void openPath(const QString &path)
    {
        // Hack to access samba shares with QDesktopServices::openUrl
        const QUrl url = path.startsWith("//")
            ? QUrl("file:" + path)
            : QUrl::fromLocalFile(path);
        QDesktopServices::openUrl(url);
    }

    // Open the parent directory of the given path with a file manager and select
    // (if possible) the item at the given path
    Q_INVOKABLE static void openFolderSelect(const QString &path)
    {
        QFileInfo f(path);
        // If the item to select doesn't exist, try to open its parent
        if (!f.exists())
        {
            openPath(f.absolutePath());
            return;
        }

    #ifdef Q_OS_WIN
        auto *thread = QThread::create([path]()
        {
            if (SUCCEEDED(::CoInitializeEx(NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE)))
            {
                const std::wstring pathWStr = path.toStdWString();
                PIDLIST_ABSOLUTE pidl = ::ILCreateFromPathW(pathWStr.c_str());
                if (pidl)
                {
                    ::SHOpenFolderAndSelectItems(pidl, 0, nullptr, 0);
                    ::ILFree(pidl);
                }

                ::CoUninitialize();
            }
        });
        QObject::connect(thread, &QThread::finished, thread, &QObject::deleteLater);
        thread->start();
    #elif defined(Q_OS_UNIX) && !defined(Q_OS_MACOS)
        QProcess proc;
        proc.start(QStringLiteral(u"xdg-mime"), {QStringLiteral(u"query"), QStringLiteral(u"default"), QStringLiteral(u"inode/directory")});
        proc.waitForFinished();
        const auto output = QString::fromLocal8Bit(proc.readLine().simplified());
        if ((output == u"dolphin.desktop") || (output == u"org.kde.dolphin.desktop"))
        {
            proc.startDetached(QStringLiteral(u"dolphin"), {QStringLiteral(u"--select"), path});
        }
        else if ((output == u"nautilus.desktop") || (output == u"org.gnome.Nautilus.desktop")
                     || (output == u"nautilus-folder-handler.desktop"))
        {
            proc.start(QStringLiteral(u"nautilus"), {QStringLiteral(u"--version")});
            proc.waitForFinished();
            proc.startDetached(QStringLiteral(u"nautilus"), {path});
        }
        else if (output == u"nemo.desktop")
        {
            proc.startDetached(QStringLiteral(u"nemo"), {QStringLiteral(u"--no-desktop"), path});
        }
        else if ((output == u"konqueror.desktop") || (output == u"kfmclient_dir.desktop"))
        {
            proc.startDetached(QStringLiteral(u"konqueror"), {QStringLiteral(u"--select"), path});
        }
        else
        {
            // "caja" manager can't pinpoint the file, see: https://github.com/qbittorrent/qBittorrent/issues/5003
            openPath(f.absolutePath());
        }
    #else
        openPath(path.parentPath());
    #endif
    }

    static QString configPath;
};

#endif // UTILITY_H
