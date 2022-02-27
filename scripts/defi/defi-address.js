let ofSession = (networkId) => {
    if (networkId == 1287) {
        return '0xc7876eda966d5d84aa81c0594dff14c7d9bce876';
    }

    throw `No Moonscape Defi smartcontract found on ${networkId}`;
};

let ofCrowns = (networkId) => {
    if (networkId == 1287) {
        return '0xfde9cad69e98b3cc8c998a8f2094293cb0bd6911';
    }

    throw `No Crowns smartcontract found on ${networkId}`;
}

module.exports = {
    ofSession,
    ofCrowns
}

