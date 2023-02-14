#include <QtTest>
#include <QString>
#include <QValidator>

#include "core/ContactIDValidator.h"
#include "core/IdentityManager.h"


class TestContactIDValidator : public QObject
{
    Q_OBJECT

private slots:
    void test_validate();
};

//todo: fix segfault due to ContactIDValidator.cpp -> identityManager->identities()[0] in test case
//ContactIDValidator validator((QObject*)NULL);

void TestContactIDValidator::test_validate()
{
    /*
    QString text = "hi";
    int pos = 0;
    QCOMPARE(validator.validate(text, pos), QValidator::Invalid);

    text = "speek:kmhee7bfsixluoummhu7rkjx6vlxksneflromksrdhhi7n5ks3ckygqd";
    pos = 0;
    QCOMPARE(validator.validate(text, pos), QValidator::Acceptable);
    */
}

QTEST_APPLESS_MAIN(TestContactIDValidator)
#include "tst_contactidvalidator.moc"
