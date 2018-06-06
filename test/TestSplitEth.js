var SplitEth = artifacts.require("./SplitEth.sol");

contract('SplitEth', function(accounts) {
    console.log(accounts);
    //Test constructor
    it("Test Bill", function() {
        return SplitEth.new()
            .then((instance) => {

                var createBillEvent = instance.logCreateBill();
                var payBillEvent = instance.logPayBill();
                var billSatisfiedEvent = instance.logBillSatisfied();
                var payableFallbackEvent = instance.logPayableFallback();
                var fundEvent = instance.logFund();
                var overageEvent = instance.logOverage();

                //Test Bill
                instance.createBill(100).then(()=>{
                    var event = createBillEvent.get()[0].args;
                    assert.equal(event.id.toNumber(), 0, "createBillEvent id should be 0");
                    assert.equal(event.owner, accounts[0], "createBillEvent owner should match accounts 0");

                    instance.getBill(accounts[0], 0).then((result)=> {
                       assert.equal(result[0].toNumber(), 100, "bill total should be 100");
                       assert.equal(result[1].toNumber(), 100, "bill balance should be 100");
                       assert.equal(result[2].toNumber(), 0, "bill payers should be 0");

                      instance.payBill(accounts[0], 0, {from: accounts[1], value: 5}).then((result)=>{
                          var event = fundEvent.get()[0].args;
                          assert.equal(event.owner, accounts[0], "payBillEvent owner should match account 0");
                          assert.equal(event.id.toNumber(), 0, "payBillEvent id should be 0");
                          assert.equal(event.payer, accounts[1], "payBillEvent payer should match account 1");
                          assert.equal(event.amount.toNumber(), 5, "payBillEvent amount should be 5");
                          assert.equal(event.balance.toNumber(), 95, "payBillEvent balance should be 95");

                         instance.getBill(accounts[0], 0).then((result)=> {
                              assert.equal(result[0].toNumber(), 100, "bill total should be 100");
                              assert.equal(result[1].toNumber(), 95, "bill balance should be 95");
                              assert.equal(result[2].toNumber(), 1, "bill payers should be 1");

                              instance.checkIfBillPaid(accounts[0], 0, accounts[1]).then((result)=>{
                                        assert.equal(result, true, "bill should be paid by account 1");
                              });
                         });
                      });
                    });
                });

                //Test Fallback
                instance.createBill(100, {from: accounts[1]}).then(()=>{
                            //Test Bill Owner and Id
                            var event = createBillEvent.get()[0].args;
                            assert.equal(event.id.toNumber(), 0, "createBillEvent id should be 0");
                            assert.equal(event.owner, accounts[0], "createBillEvent owner should match accounts 0");

                            var id = 0;
                                var parameters = accounts[0] + ',' + id;
                                instance.sendTransaction({value: 10, from: accounts[1], data: web3.toHex(parameters)}).then(()=>{
                                    var fallbackEvent = payableFallbackEvent.get();
                                    console.log(fallbackEvent);
                                    var fe =  fundEvent.get();
                                    console.log(fe);
                                    instance.getBill(accounts[0], 0).then((result)=>{
                                       console.log(result[0].toNumber());
                                       console.log(result[1].toNumber());
                                       console.log(result[2].toNumber());
                                    });
                 });
          });
    });
});
