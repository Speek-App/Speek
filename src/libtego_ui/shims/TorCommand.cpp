#include "TorCommand.h"

namespace shims
{
    void TorControlCommand::onFinished(bool success)
    {
        this->m_successful = success;
        emit this->finished(success);
        this->deleteLater();
    }

    bool TorControlCommand::isSuccessful() const
    {
        return m_successful;
    }
}
