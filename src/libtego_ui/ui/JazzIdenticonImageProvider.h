#ifndef JAZZIDENTICONIMAGEPROVIDER_H
#define JAZZIDENTICONIMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QBitmap>
#include <QPainter>
#include <random>
#include <math.h>
#include <QColor>
#include <QPixmap>
#include <QFile>

std::uniform_real_distribution<double> dis(0.0, 1.0);

class JazzIdenticonImageProvider : public QQuickImageProvider
{
private:
    const int shapeCount = 5;
    const int wobble = 30;

    std::vector<std::string> colors = {
          "#01888C", // teal
          "#FC7500", // bright orange
          "#034F5D", // dark teal
          "#F73F01", // orangered
          "#FC1960", // magenta
          "#C7144C", // raspberry
          "#F3C100", // goldenrod
          "#1598F2", // lightning blue
          "#2465E1", // sail blue
          "#F19E02", // gold
    };

    std::string genColor(std::vector<std::string> &remainingColors, std::mt19937& generator) {
      int idx = floor(static_cast<double>(remainingColors.size()) * dis(generator));
      std::string color = remainingColors[idx];
      remainingColors.erase(remainingColors.begin() + idx);
      return color;
    }

    std::vector<std::string> hueShift(std::mt19937& generator) {
      int amount = (dis(generator) * 30) - (wobble / 2);
      std::vector<std::string> colors_n;
      for(size_t i = 0; i<colors.size(); i++){
          QColor c(QString::fromStdString(colors[i]));
          //double hue = c.hue() + amount;
          int hue = (c.hue() + amount) % 360;
          hue = hue < 0 ? 360 + hue : hue;
          c.setHsl(hue,c.saturation(),c.lightness());
          colors_n.push_back(c.name().toStdString());
      }
      return colors_n;
    }

    void genShape(std::vector<std::string> &remainingColors, int diameter, int i, int total, QPixmap &pixmap, std::mt19937& generator) {
      int center = diameter / 2;
      double firstRot = dis(generator);
      double angle = M_PI * 2 * firstRot;
      double velocity = diameter / total * dis(generator) + (i * diameter / total);

      double tx = (cos(angle) * velocity);
      double ty = (sin(angle) * velocity);

      double secondRot = dis(generator);
      double rot = (firstRot * 360) + secondRot * 180;

      QColor qc(QString::fromStdString(genColor(remainingColors, generator)));
      QPainter painter( &pixmap );
      painter.setBrush(qc);
      painter.setPen(Qt::NoPen);
      painter.setRenderHint(QPainter::Antialiasing);
      painter.translate(tx+center,ty+center);
      painter.rotate(rot);
      painter.drawRect(0,0,diameter,diameter);
      painter.translate(-tx,-ty);
      painter.end();
    }

    void generateIdenticon(int diameter, unsigned seed, QPixmap &pixmap) {
      std::mt19937 generator;
      generator.seed(seed);
      std::vector<std::string> remainingColors = hueShift(generator);

      QColor qc(QString::fromStdString(genColor(remainingColors, generator)));
      QPainter painter( &pixmap );
      painter.setPen(Qt::NoPen);
      painter.setBrush(qc);
      painter.setRenderHint(QPainter::Antialiasing);
      painter.drawEllipse(0,0,diameter,diameter);
      painter.end();

      for(int i = 0; i < shapeCount - 1; i++) {
        genShape(remainingColors, diameter, i, shapeCount - 1, pixmap, generator);
      }
    }

public:
    JazzIdenticonImageProvider()
               : QQuickImageProvider(QQuickImageProvider::Pixmap)
    {
    }

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override
    {
        int w = requestedSize.width() > 0 ? requestedSize.width() : size->width();
        int h = requestedSize.height() > 0 ? requestedSize.height() : size->height();

        unsigned seed = id.mid(0,8).toUInt(NULL, 16);
        QPixmap pixmap(200, 200);

        generateIdenticon(200, seed, pixmap);
        QBitmap map(pixmap.width(),pixmap.height());
        map.fill(Qt::color0);

        QPainter painter( &map );
        painter.setBrush(Qt::color1);
        painter.setPen(Qt::NoPen);
        painter.setRenderHint(QPainter::Antialiasing);
        painter.drawEllipse(1,1,pixmap.width()-2,pixmap.height()-2);
        painter.setRenderHint(QPainter::Antialiasing);
        painter.end();

        pixmap.setMask(map);

        pixmap = pixmap.scaled(w,h,Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);

        return pixmap;
    }
};

#endif // JAZZIDENTICONIMAGEPROVIDER_H
