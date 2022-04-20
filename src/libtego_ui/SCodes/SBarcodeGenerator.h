#ifndef SBARCODEGENERATOR_H
#define SBARCODEGENERATOR_H

#include <QDir>
#include <QImage>
#include <qqml.h>
#include <QQuickItem>
#include <QObject>

#include "BitMatrix.h"
#include "ByteMatrix.h"

#include "SBarcodeFormat.h"

class SBarcodeGenerator : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(int width MEMBER _width NOTIFY widthChanged)
    Q_PROPERTY(int height MEMBER _height NOTIFY heightChanged)
    Q_PROPERTY(int margin MEMBER _margin NOTIFY marginChanged)
    Q_PROPERTY(int eccLevel MEMBER _eccLevel NOTIFY eccLevelChanged)
    Q_PROPERTY(QString fileName MEMBER _fileName NOTIFY fileNameChanged)
    Q_PROPERTY(QString extension MEMBER _extension)
    Q_PROPERTY(QString filePath MEMBER _filePath)
    Q_PROPERTY(QString inputText MEMBER _inputText)
    Q_PROPERTY(SCodes::SBarcodeFormat format READ format WRITE setFormat NOTIFY formatChanged)

#if (QT_VERSION >= QT_VERSION_CHECK(5, 15, 0))
        QML_ELEMENT
#endif

public:
    explicit SBarcodeGenerator(QQuickItem *parent = nullptr);
    ~SBarcodeGenerator() override {};

    SCodes::SBarcodeFormat format() const;
    void setFormat(SCodes::SBarcodeFormat format);

public slots:
    bool generate(const QString &inputString);
    void setFormat(const QString &formatName);
    bool saveImage();

signals:
    void generationFinished(const QString &error = "");
    void widthChanged(int width);
    void heightChanged(int height);
    void marginChanged(int margin);
    void eccLevelChanged(int eccLevel);
    void fileNameChanged(const QString &fileName);

    void formatChanged(SCodes::SBarcodeFormat format);

private:
    int _width = 500;
    int _height = 500;
    int _margin = 10;
    int _eccLevel = -1;

    QString _extension = "png";
    QString _fileName = "code";
    QString _filePath = "";
    QString _inputText = "";
    SCodes::SBarcodeFormat m_format = SCodes::SBarcodeFormat::Code128;

    ZXing::Matrix<uint8_t> _bitmap = ZXing::Matrix<uint8_t>();
};

#endif // SBARCODEGENERATOR_H
