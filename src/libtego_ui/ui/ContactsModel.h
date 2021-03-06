/* Speek - https://speek.network/
 * Copyright (C) 2020, Speek Network (contact@speek.network)
 * Copyright (C) 2014, John Brooks <john.brooks@dereferenced.net>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *    * Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *    * Redistributions in binary form must reproduce the above
 *      copyright notice, this list of conditions and the following disclaimer
 *      in the documentation and/or other materials provided with the
 *      distribution.
 *
 *    * Neither the names of the copyright owners nor the names of its
 *      contributors may be used to endorse or promote products derived from
 *      this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef CONTACTSMODEL_H
#define CONTACTSMODEL_H


namespace shims
{
    class UserIdentity;
    class ContactUser;
}


class ContactsModel : public QAbstractListModel
{
    Q_OBJECT
    Q_DISABLE_COPY(ContactsModel)

public:
    enum
    {
        PointerRole = Qt::UserRole,
        StatusRole,
        AlertRole /* bool */,
        SectionRole
    };

    explicit ContactsModel(QObject *parent = 0);

    Q_INVOKABLE QModelIndex indexOfContact(shims::ContactUser *user) const;
    Q_INVOKABLE int rowOfContact(shims::ContactUser *user) const { return indexOfContact(user).row(); }
    Q_INVOKABLE shims::ContactUser *contact(int row) const;

    virtual int rowCount(const QModelIndex &parent = QModelIndex()) const;
    virtual QHash<int,QByteArray> roleNames() const;
    virtual QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;

signals:
    void identityChanged();

private slots:
    void updateUser(shims::ContactUser *user = 0);
    void contactAdded(shims::ContactUser *user);
    void contactRemoved(shims::ContactUser *user);

private:
    void setIdentity();

    shims::UserIdentity *m_identity;
    QList<shims::ContactUser*> contacts;

    void connectSignals(shims::ContactUser *user);
};

#endif // CONTACTSMODEL_H
